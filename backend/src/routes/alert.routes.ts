import { Router } from 'express';
import { handlePubSubTrigger } from '../controllers/alert.controller';

const router = Router();

// Endpoint intended to be called securely by a Google Cloud Pub/Sub push subscription
router.post('/pubsub', handlePubSubTrigger);

export default router;
