#!/usr/bin/env python3
"""
AI 카드 자동 생성 스크립트

Genspark AI image_generation tool을 사용하여 Weekly Gacha 카드를 자동 생성합니다.
- 70장 카드 자동 생성
- Firebase Storage 자동 업로드
- Firestore 자동 저장
- 실시간 진행상황 표시
"""

import os
import sys
import json
import time
from typing import List, Dict, Optional
from datetime import datetime

# Firebase Admin SDK
try:
    import firebase_admin
    from firebase_admin import credentials, firestore, storage
    print("✅ Firebase Admin SDK imported successfully")
except ImportError:
    print("❌ Firebase Admin SDK not found!")
    print("📦 Installing firebase-admin...")
    os.system("pip install firebase-admin==7.1.0")
    import firebase_admin
    from firebase_admin import credentials, firestore, storage

# 카드 희귀도 정의
class CardRarity:
    NORMAL = 'normal'
    RARE = 'rare'
    SUPER_RARE = 'superRare'
    ULTRA_RARE = 'ultraRare'
    SECRET = 'secret'

# 카드 스타일 정의
class CardStyle:
    CUTE = 'cute'
    CYBERPUNK = 'cyberpunk'
    CARTOON = 'cartoon'
    FANTASY = 'fantasy'
    PIXEL_ART = 'pixelArt'
    REALISTIC = 'realistic'

# 생성 모드 정의
class GenerationMode:
    EVOLUTION = 'evolution'
    THEMATIC = 'thematic'
    HYBRID = 'hybrid'

class AICardGenerator:
    """AI 카드 생성 엔진"""
    
    def __init__(self, firebase_key_path: str = '/opt/flutter/firebase-admin-sdk.json'):
        """초기화"""
        self.firebase_key_path = firebase_key_path
        self.db = None
        self.bucket = None
        self.season_id = f"2025_S{self._get_current_season()}_v1"
        
        # Firebase 초기화
        self._init_firebase()
    
    def _get_current_season(self) -> int:
        """현재 시즌 번호 계산 (주차 기반)"""
        import datetime
        now = datetime.datetime.now()
        # 2025년 1월 1일부터 주차 계산
        start_of_year = datetime.datetime(2025, 1, 1)
        week_number = (now - start_of_year).days // 7 + 1
        return week_number
    
    def _init_firebase(self):
        """Firebase Admin SDK 초기화"""
        try:
            # Firebase Admin SDK 키 파일 확인
            if not os.path.exists(self.firebase_key_path):
                print(f"❌ Firebase key not found: {self.firebase_key_path}")
                print("📝 Please upload firebase-admin-sdk.json to /opt/flutter/")
                sys.exit(1)
            
            # Firebase 앱 초기화 (이미 초기화된 경우 건너뛰기)
            if not firebase_admin._apps:
                cred = credentials.Certificate(self.firebase_key_path)
                firebase_admin.initialize_app(cred, {
                    'storageBucket': 'weeklygacha-24683.firebasestorage.app'
                })
                print("✅ Firebase initialized")
            
            self.db = firestore.client()
            self.bucket = storage.bucket()
            print(f"✅ Connected to Firebase Storage: {self.bucket.name}")
            
        except Exception as e:
            print(f"❌ Firebase initialization failed: {e}")
            sys.exit(1)
    
    def build_image_prompt(self, card_name: str, description: str, 
                          rarity: str, style: str) -> str:
        """AI 이미지 생성 프롬프트 빌드"""
        
        # 스타일별 프롬프트 접두사
        style_prompts = {
            CardStyle.CUTE: 'Cute and adorable style, kawaii aesthetic, soft pastel colors, charming, chibi-like proportions',
            CardStyle.CYBERPUNK: 'Cyberpunk style, neon colors, futuristic, high-tech, glowing effects, dark background',
            CardStyle.CARTOON: 'Cartoon style, bold outlines, vibrant colors, animated look, expressive features',
            CardStyle.FANTASY: 'Fantasy art style, magical, ethereal, detailed, epic, mystical atmosphere',
            CardStyle.PIXEL_ART: '16-bit pixel art style, retro gaming aesthetic, detailed pixels, nostalgic',
            CardStyle.REALISTIC: 'Realistic style, photorealistic, detailed textures, natural lighting, high definition'
        }
        
        # 희귀도별 품질 강조
        rarity_boosts = {
            CardRarity.SECRET: 'legendary masterpiece, extremely detailed, holographic effect, premium quality, epic lighting',
            CardRarity.ULTRA_RARE: 'epic quality, highly detailed, glowing golden aura, premium, shimmering effects',
            CardRarity.SUPER_RARE: 'rare quality, detailed artwork, special silver effects, quality craftsmanship',
            CardRarity.RARE: 'uncommon quality, good details, slight magical glow, polished',
            CardRarity.NORMAL: 'standard quality, clean design, professional artwork'
        }
        
        style_prefix = style_prompts.get(style, style_prompts[CardStyle.CUTE])
        rarity_boost = rarity_boosts.get(rarity, rarity_boosts[CardRarity.NORMAL])
        
        # 최종 프롬프트 조합
        prompt = (
            f"{style_prefix}, "
            f"{description}, "
            f"{rarity_boost}, "
            f"trading card art, centered composition, "
            f"clean white background, professional illustration, "
            f"suitable for mobile game, high quality digital art"
        )
        
        return prompt
    
    def generate_card_concepts(self, mode: str, theme: str, 
                               style: str, custom_names: List[str] = None) -> List[Dict]:
        """카드 컨셉 생성"""
        
        if mode == GenerationMode.EVOLUTION:
            return self._generate_evolution_concepts(theme, style, custom_names)
        elif mode == GenerationMode.THEMATIC:
            return self._generate_thematic_concepts(theme, style)
        else:  # HYBRID
            return self._generate_hybrid_concepts(theme, style)
    
    def _generate_evolution_concepts(self, theme: str, style: str, 
                                    custom_names: List[str] = None) -> List[Dict]:
        """진화 시스템 카드 컨셉 (20 creatures × 5 stages = 100 → filter to 70)"""
        
        # 기본 생명체 이름 (20마리)
        if custom_names and len(custom_names) == 20:
            creature_names = custom_names
        else:
            # 테마별 기본 생명체
            if '몬스터' in theme or '포켓몬' in theme:
                creature_names = [
                    '파이리', '꼬부기', '이상해씨', '피카츄', '잠만보',
                    '뮤츠', '루기아', '레쿠쟈', '가디안', '리자몽',
                    '갸라도스', '망나뇽', '메타그로스', '보만다', '루카리오',
                    '가브리아스', '메가니움', '블레이범', '샤로다', '염무왕'
                ]
            elif '공룡' in theme:
                creature_names = [
                    '티라노', '트리케라', '브라키오', '스테고', '벨로시',
                    '프테라노', '디플로도쿠스', '스피노', '알로', '파키케팔로',
                    '이구아노돈', '안킬로', '갈리미무스', '카르노', '기가노토',
                    '테리지노', '케찰코아틀루스', '모사사우루스', '타르보', '바리오닉스'
                ]
            elif '해괴한' in theme or '퉁퉁퉁' in theme:
                creature_names = [
                    '퉁퉁퉁사우르스', '몽글몽글이', '삐뚤빼뚤', '우걱우걱',
                    '꾸물꾸물이', '덜컹덜컹', '꿀렁꿀렁이', '쿨럭쿨럭',
                    '흔들흔들이', '뒤뚱뒤뚱', '빙글빙글이', '펄럭펄럭',
                    '흐물흐물이', '철컥철컥', '둥둥둥이', '쿵쿵쿵',
                    '찡긋찡긋이', '포슬포슬', '탱글탱글이', '쫀득쫀득'
                ]
            else:
                creature_names = [f'{theme} #{i+1}' for i in range(20)]
        
        # 5단계 진화 컨셉
        all_cards = []
        for i, name in enumerate(creature_names):
            stages = [
                {'stage': 1, 'rarity': CardRarity.NORMAL, 'prefix': '알'},
                {'stage': 2, 'rarity': CardRarity.RARE, 'prefix': '새끼'},
                {'stage': 3, 'rarity': CardRarity.SUPER_RARE, 'prefix': '성체'},
                {'stage': 4, 'rarity': CardRarity.ULTRA_RARE, 'prefix': '강화'},
                {'stage': 5, 'rarity': CardRarity.SECRET, 'prefix': '궁극'}
            ]
            
            for stage in stages:
                card = {
                    'index': len(all_cards),
                    'name': f"{stage['prefix']} {name}",
                    'description': f"{name}의 {stage['stage']}단계 진화형. 진화할수록 강력해집니다!",
                    'rarity': stage['rarity'],
                    'evolution_line': i + 1,
                    'evolution_stage': stage['stage']
                }
                all_cards.append(card)
        
        # 100장 → 70장 필터링 (희귀도별 분배)
        # Normal: 20, Rare: 20, Super Rare: 20, Ultra Rare: 9, Secret: 1
        filtered = []
        filtered.extend([c for c in all_cards if c['rarity'] == CardRarity.NORMAL][:20])
        filtered.extend([c for c in all_cards if c['rarity'] == CardRarity.RARE][:20])
        filtered.extend([c for c in all_cards if c['rarity'] == CardRarity.SUPER_RARE][:20])
        filtered.extend([c for c in all_cards if c['rarity'] == CardRarity.ULTRA_RARE][:9])
        filtered.extend([c for c in all_cards if c['rarity'] == CardRarity.SECRET][:1])
        
        # 인덱스 재조정
        for i, card in enumerate(filtered):
            card['index'] = i
        
        return filtered
    
    def _generate_thematic_concepts(self, theme: str, style: str) -> List[Dict]:
        """테마 기반 독립 카드 (70장)"""
        
        # 희귀도 분배: Normal 20, Rare 20, Super Rare 20, Ultra Rare 9, Secret 1
        rarity_distribution = (
            [CardRarity.NORMAL] * 20 +
            [CardRarity.RARE] * 20 +
            [CardRarity.SUPER_RARE] * 20 +
            [CardRarity.ULTRA_RARE] * 9 +
            [CardRarity.SECRET] * 1
        )
        
        cards = []
        for i, rarity in enumerate(rarity_distribution):
            card = {
                'index': i,
                'name': f'{theme} #{i+1}',
                'description': f'{theme} 테마의 유니크한 카드',
                'rarity': rarity
            }
            cards.append(card)
        
        return cards
    
    def _generate_hybrid_concepts(self, theme: str, style: str) -> List[Dict]:
        """하이브리드: 진화 + 독립 카드"""
        
        # 50% 진화형, 50% 독립 카드
        evolution_cards = self._generate_evolution_concepts(theme, style)[:35]
        thematic_cards = self._generate_thematic_concepts(theme, style)[:35]
        
        all_cards = evolution_cards + thematic_cards
        
        # 인덱스 재조정
        for i, card in enumerate(all_cards):
            card['index'] = i
        
        return all_cards
    
    def generate_single_card_image(self, card_concept: Dict, style: str) -> Optional[str]:
        """
        단일 카드 이미지 생성 (Genspark AI 활용)
        
        실제 Genspark SDK를 사용하여 이미지 생성
        """
        
        prompt = self.build_image_prompt(
            card_name=card_concept['name'],
            description=card_concept['description'],
            rarity=card_concept['rarity'],
            style=style
        )
        
        print(f"   🎨 Generating: {card_concept['name']}")
        print(f"   📝 Prompt: {prompt[:80]}...")
        
        try:
            # ✅ 실제 Genspark SDK 사용
            import asyncio
            from genspark_sdk import GenSparkSDK
            
            async def generate_async():
                async with GenSparkSDK(timeout=120.0, verbose=False) as client:
                    result = await client.image_generation(
                        query=prompt,
                        model='recraft-v3',  # 빠르고 경제적 (512x512, $0.02)
                        aspect_ratio='1:1',
                        image_urls=[],
                        task_summary=f'Generate Weekly Gacha card: {card_concept["name"]}'
                    )
                    return result
            
            # 동기 함수에서 async 함수 실행
            result = asyncio.run(generate_async())
            
            # 결과에서 이미지 URL 추출
            # Genspark SDK는 마크다운 형식으로 반환하므로 URL 파싱
            import re
            url_match = re.search(r'https?://[^\s\)]+', result)
            if url_match:
                image_url = url_match.group(0)
                print(f"   ✅ Image generated: {image_url[:60]}...")
                return image_url
            else:
                print(f"   ⚠️ Could not extract URL from result")
                return None
                
        except Exception as e:
            print(f"   ❌ Generation failed: {e}")
            # 에러 발생 시 None 반환 (재시도 로직에서 처리)
            return None
    
    def upload_to_firebase_storage(self, image_url: str, card_index: int) -> str:
        """Firebase Storage에 이미지 업로드"""
        
        import requests
        from io import BytesIO
        
        try:
            # 이미지 다운로드
            response = requests.get(image_url, timeout=30)
            response.raise_for_status()
            
            image_data = BytesIO(response.content)
            
            # Firebase Storage 경로
            storage_path = f'seasons/{self.season_id}/cards/card_{card_index}.png'
            blob = self.bucket.blob(storage_path)
            
            # 업로드
            blob.upload_from_file(image_data, content_type='image/png')
            blob.make_public()
            
            download_url = blob.public_url
            print(f"   ✅ Uploaded to: {storage_path}")
            
            return download_url
            
        except Exception as e:
            print(f"   ❌ Upload failed: {e}")
            return image_url  # 실패 시 원본 URL 반환
    
    def save_to_firestore(self, cards_data: List[Dict]):
        """Firestore에 카드 데이터 저장 (배치 처리)"""
        
        batch = self.db.batch()
        
        for card in cards_data:
            card_id = f"card_{card['index']}"
            doc_ref = self.db.collection('seasons').document(self.season_id).collection('cards').document(card_id)
            
            batch.set(doc_ref, {
                'id': card_id,
                'name': card['name'],
                'rarity': card['rarity'],
                'imagePath': card.get('imagePath', ''),
                'description': card['description'],
                'maxSupply': 1000,
                'createdAt': firestore.SERVER_TIMESTAMP,
                'generatedAt': datetime.now().isoformat(),
                'seasonId': self.season_id
            })
        
        batch.commit()
        print(f"✅ Saved {len(cards_data)} cards to Firestore")
    
    def generate_full_season(self, mode: str, theme: str, style: str, 
                            custom_names: List[str] = None) -> Dict:
        """전체 시즌 카드 생성 (70장)"""
        
        print("=" * 60)
        print("🎴 Weekly Gacha AI Card Generation")
        print("=" * 60)
        print(f"📅 Season: {self.season_id}")
        print(f"🎯 Mode: {mode}")
        print(f"🎨 Theme: {theme}")
        print(f"✨ Style: {style}")
        print(f"📦 Total Cards: 70")
        print("=" * 60)
        
        start_time = time.time()
        
        # 1단계: 카드 컨셉 생성
        print("\n[1/3] 📝 Generating card concepts...")
        card_concepts = self.generate_card_concepts(mode, theme, style, custom_names)
        print(f"✅ Generated {len(card_concepts)} card concepts")
        
        # 2단계: AI 이미지 생성
        print("\n[2/3] 🎨 Generating AI images (70 cards)...")
        print("⏱️  Estimated time: 30-40 minutes")
        print("-" * 60)
        
        generated_cards = []
        failed_cards = []
        
        for i, concept in enumerate(card_concepts):
            print(f"\n[{i+1}/70] Processing: {concept['name']}")
            
            try:
                # AI 이미지 생성
                image_url = self.generate_single_card_image(concept, style)
                
                if image_url:
                    # Firebase Storage 업로드
                    storage_url = self.upload_to_firebase_storage(image_url, i)
                    concept['imagePath'] = storage_url
                    generated_cards.append(concept)
                else:
                    failed_cards.append(concept)
                    print(f"   ⚠️  Generation failed")
                
            except Exception as e:
                print(f"   ❌ Error: {e}")
                failed_cards.append(concept)
            
            # 진행률 표시
            progress = (i + 1) / len(card_concepts) * 100
            print(f"   📊 Progress: {progress:.1f}% ({i+1}/70)")
        
        # 3단계: Firestore 저장
        print("\n[3/3] 💾 Saving to Firestore...")
        self.save_to_firestore(generated_cards)
        
        elapsed_time = time.time() - start_time
        
        # 결과 요약
        print("\n" + "=" * 60)
        print("✅ Generation Complete!")
        print("=" * 60)
        print(f"✅ Successful: {len(generated_cards)}/70")
        print(f"❌ Failed: {len(failed_cards)}/70")
        print(f"⏱️  Time: {elapsed_time/60:.1f} minutes")
        print(f"🔗 Season ID: {self.season_id}")
        print("=" * 60)
        
        return {
            'success': len(failed_cards) == 0,
            'generated': len(generated_cards),
            'failed': len(failed_cards),
            'season_id': self.season_id,
            'elapsed_time': elapsed_time
        }


def main():
    """메인 실행 함수"""
    
    print("\n🎴 Weekly Gacha AI Card Generator")
    print("=" * 60)
    
    # 사용자 입력
    print("\n📋 Generation Configuration:")
    print("-" * 60)
    
    # 모드 선택
    print("\n1. Generation Mode:")
    print("   a) Evolution (진화 시스템 - 20 creatures × 5 stages)")
    print("   b) Thematic (테마 기반 - 70 independent cards)")
    print("   c) Hybrid (하이브리드 - 진화 + 독립)")
    mode_choice = input("Select mode (a/b/c) [a]: ").strip().lower() or 'a'
    
    mode_map = {'a': GenerationMode.EVOLUTION, 'b': GenerationMode.THEMATIC, 'c': GenerationMode.HYBRID}
    mode = mode_map.get(mode_choice, GenerationMode.EVOLUTION)
    
    # 테마 선택
    print("\n2. Theme:")
    print("   a) 진화하는 몬스터 (Pokemon-style)")
    print("   b) 해괴한 생명체 (퉁퉁퉁사우르스)")
    print("   c) 귀여운 동물들")
    print("   d) 귀여운 공룡들")
    print("   e) Custom theme")
    theme_choice = input("Select theme (a/b/c/d/e) [a]: ").strip().lower() or 'a'
    
    theme_map = {
        'a': '진화하는 몬스터',
        'b': '해괴한 생명체',
        'c': '귀여운 동물들',
        'd': '귀여운 공룡들'
    }
    
    if theme_choice == 'e':
        theme = input("Enter custom theme: ").strip()
    else:
        theme = theme_map.get(theme_choice, '진화하는 몬스터')
    
    # 스타일 선택
    print("\n3. Art Style:")
    print("   a) Cute (귀여운)")
    print("   b) Cyberpunk (사이버펑크)")
    print("   c) Cartoon (카툰/만화)")
    print("   d) Fantasy (판타지)")
    print("   e) Pixel Art (픽셀 아트)")
    print("   f) Realistic (사실적)")
    style_choice = input("Select style (a/b/c/d/e/f) [a]: ").strip().lower() or 'a'
    
    style_map = {
        'a': CardStyle.CUTE,
        'b': CardStyle.CYBERPUNK,
        'c': CardStyle.CARTOON,
        'd': CardStyle.FANTASY,
        'e': CardStyle.PIXEL_ART,
        'f': CardStyle.REALISTIC
    }
    style = style_map.get(style_choice, CardStyle.CUTE)
    
    # 확인
    print("\n" + "=" * 60)
    print("📋 Configuration Summary:")
    print(f"   Mode: {mode}")
    print(f"   Theme: {theme}")
    print(f"   Style: {style}")
    print(f"   Cards: 70")
    print(f"   Est. Time: 30-40 minutes")
    print(f"   Est. Cost: $2.80 (1024×1024)")
    print("=" * 60)
    
    confirm = input("\n⚠️  Start generation? (yes/no) [yes]: ").strip().lower() or 'yes'
    
    if confirm != 'yes':
        print("❌ Generation cancelled")
        return
    
    # AI 생성기 초기화 및 실행
    generator = AICardGenerator()
    result = generator.generate_full_season(
        mode=mode,
        theme=theme,
        style=style
    )
    
    # 결과 출력
    if result['success']:
        print("\n🎉 All cards generated successfully!")
    else:
        print(f"\n⚠️  Generation completed with {result['failed']} failures")
    
    print(f"\n🔗 View in Firebase Console:")
    print(f"   https://console.firebase.google.com/project/weeklygacha-24683/firestore")
    print(f"   Collection: seasons/{result['season_id']}/cards")


if __name__ == '__main__':
    main()
