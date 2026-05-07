from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import google.generativeai as genai
import os

# Set your API key here or use environment variable
API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBH-jBycJUxYd5CaoeuAbjEsSAbCWBcrUM")
genai.configure(api_key=API_KEY)

# Define the system instruction for the AI Chef, explicitly telling it to answer questions as well.
SYSTEM_INSTRUCTION = """Sen deneyimli ve yardımsever bir Türk mutfak asistanısın. Adın "AI Şef".
Görevin kullanıcılara yemek tarifleri vermek, mutfak ipuçları sunmak, malzeme önerilerinde bulunmak ve mutfak/yemek dışındaki konularda da genel sorulara kibar ve yardımcı bir şekilde cevap vermektir.
Yanıt verirken şu kurallara uy:
- Her zaman Türkçe yanıt ver.
- Kısa ve net ol, gereksiz açıklamalardan kaçın.
- Samimi ve teşvik edici bir ton kullan.
- Tarif verirken adım adım yönlendirme yap, malzeme miktarlarını ve pişirme sürelerini belirt.
- Sana yemek dışı veya genel sorular sorulduğunda da elinden geldiğince doğru ve yardımcı cevaplar ver. Sadece bir şef olmadığını, aynı zamanda akıllı bir asistan olduğunu göster.
- Emoji kullan ama abartma."""

model = genai.GenerativeModel(
    model_name="gemini-2.5-flash",
    system_instruction=SYSTEM_INSTRUCTION,
)

app = FastAPI(title="Akıllı Mutfak API")

# Add CORS middleware to allow requests from Flutter (especially for web testing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ChatMessage(BaseModel):
    text: str
    isAI: bool

class ChatRequest(BaseModel):
    message: str
    history: List[ChatMessage] = []
    ingredients: Optional[List[str]] = []

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    try:
        # Format the history for Gemini
        gemini_history = []
        for msg in request.history:
            # We skip the "Düşünüyorum..." and the welcome messages if we want, but letting them in is fine.
            if msg.text in ["🤔 Düşünüyorum...", "🍳 Elinizde hangi malzemeler var? Söyleyin, size harika bir tarif çıkarayım!", "👨‍🍳 Merhaba! Ben AI Şef. Bugün mutfakta size nasıl yardımcı olabilirim?"]:
                continue
                
            role = "model" if msg.isAI else "user"
            gemini_history.append({
                "role": role,
                "parts": [msg.text]
            })

        # Start chat session with the formatted history
        chat = model.start_chat(history=gemini_history)

        # Prepare the current prompt
        prompt = request.message
        if request.ingredients and len(request.ingredients) > 0:
            ingredients_str = ", ".join(request.ingredients)
            prompt = f"Kullanıcının elindeki malzemeler: {ingredients_str}\nBunları göz önünde bulundurarak yanıt ver.\nKullanıcı sorusu: \"{request.message}\"\nYalnızca mevcut malzemeleri kullanarak öneri sun."

        # Send the message
        response = chat.send_message(prompt)
        
        return {"response": response.text}
    except Exception as e:
        print(f"Error calling Gemini: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
