const express = require('express');
const router = express.Router();
const medicineController = require('../controllers/medicineController');
const authMiddleware = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authMiddleware);

// GET /api/medicines - Get all medicines for logged-in user
router.get('/', medicineController.getAllMedicines);

// POST /api/medicines - Add new medicine
router.post('/', medicineController.addMedicine);

// PUT /api/medicines/:id - Update medicine
router.put('/:id', medicineController.updateMedicine);

// DELETE /api/medicines/:id - Delete medicine
router.delete('/:id', medicineController.deleteMedicine);

module.exports = router;