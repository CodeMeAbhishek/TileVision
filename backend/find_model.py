import os
import replicate
from dotenv import load_dotenv

load_dotenv()

def find_model():
    token = os.getenv("REPLICATE_API_TOKEN")
    if not token:
        print("Error: No token found")
        return

    client = replicate.Client(api_token=token)
    
    models_to_try = [
        "lucataco/controlnet-tile",
        "batouresearch/sdxl-controlnet-lora",  
        "bgf/controlnet-tile-sdxl",
        "jagilley/controlnet-tile"
    ]
    
    print(f"Searching for models with token: {token[:4]}...")
    
    for model_name in models_to_try:
        try:
            print(f"\nChecking {model_name}...")
            model = client.models.get(model_name)
            latest_version = model.latest_version
            print(f"✅ FOUND: {model_name}")
            print(f"   ID: {latest_version.id}")
        except Exception as e:
            print(f"❌ Failed {model_name}: {str(e)}")

if __name__ == "__main__":
    find_model()
