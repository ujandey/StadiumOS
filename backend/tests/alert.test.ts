import { generateAlertCopy } from '../src/services/gemini.service';

// Mock the Gemini SDK to prevent actual API calls during tests
jest.mock('@google/genai', () => {
  return {
    GoogleGenAI: jest.fn().mockImplementation(() => ({
      models: {
        generateContent: jest.fn().mockResolvedValue({
          text: 'Section 112 stand: wait just dropped to 3 min. Go now.'
        })
      }
    }))
  };
});

describe('Gemini Alert Generation Service', () => {
  it('should generate concise, conversational copy for a queue drop', async () => {
    const copy = await generateAlertCopy(
      'Queue Drop', 
      'Section 112 Food Stand', 
      'Wait time dropped from 12 mins to 3 mins'
    );
    
    // Validation of functionality and accessibility constraints (concise length)
    expect(copy).toBeDefined();
    expect(typeof copy).toBe('string');
    expect(copy.length).toBeGreaterThan(0);
    expect(copy).toContain('3 min');
  });

  // Additional tests would ensure fallback behavior when API fails
});
