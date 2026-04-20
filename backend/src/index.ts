import express from 'express';
import dotenv from 'dotenv';
import alertRoutes from './routes/alert.routes';
import { initializeFirebase } from './services/firebase.service';

dotenv.config();

// Initialize Google Services (Firebase Admin SDK)
initializeFirebase();

const app = express();

// Middleware
app.use(express.json());

// Routes
app.use('/api/alerts', alertRoutes);

// Health check for Google Cloud Run
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'stadiumos-pulse-network' });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`[StadiumOS Backend] Server running on port ${PORT}`);
});
