import dotenv from 'dotenv';

dotenv.config();

/**
 * Generates natural language copy for a venue alert using Gemini 2.0.
 * Utilizes prompt engineering for concise, helpful, and accessible language.
 */
export const generateAlertCopy = async (
  triggerType: string, 
  location: string, 
  context: string
): Promise<string> => {
  try {
    const prompt = `
      You are StadiumOS, an AI assistant for fans at a stadium.
      Write a short, conversational, first-person push notification (max 12 words) for a fan.
      Do NOT include hashtags or emojis. Be direct, helpful, and inclusive (accessible language).
      
      Alert Type: ${triggerType}
      Location Context: ${location}
      Event Context: ${context}
    `;

    // Dynamically import ESM-only package in CommonJS
    const { GoogleGenAI } = await import('@google/genai');
    const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

    // We use gemini-2.5-flash for efficient, low-latency text generation suitable for real-time alerts.
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: prompt,
      config: {
        temperature: 0.2, // Low temperature for consistent output structure
      }
    });

    const copy = response.text?.trim();
    if (!copy) throw new Error('Empty response from Gemini');
    
    return copy;
  } catch (error) {
    console.error('[Gemini] Error generating content:', error);
    // Graceful degradation: Fallback to structured text if AI service fails
    return `Update: ${triggerType} at ${location}.`;
  }
};
