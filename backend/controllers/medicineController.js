const db = require('../config/database');

// Log activity helper function
async function logActivity(userId, action, details) {
  try {
    await db.query(
      'INSERT INTO activity_logs (user_id, action, details) VALUES (?, ?, ?)',
      [userId, action, JSON.stringify(details)]
    );
  } catch (error) {
    console.error('Failed to log activity:', error);
  }
}

// Get all medicines for logged-in user
exports.getAllMedicines = async (req, res) => {
  try {
    const userId = req.userId;

    console.log('Fetching medicines for user:', userId); // Debug

    const [medicines] = await db.query(
      'SELECT id, user_id, name, dosage, purpose, frequency, times FROM medicines WHERE user_id = ? ORDER BY id DESC',
      [userId]
    );

    console.log('Raw medicines from DB:', medicines); // Debug

    // Parse JSON times field safely
    const parsedMedicines = medicines.map(med => {
      let times;
      try {
        if (typeof med.times === 'string') {
          times = JSON.parse(med.times);
        } else {
          times = med.times;
        }
      } catch (e) {
        console.error('Error parsing times for medicine:', med.id, e);
        times = [];
      }

      return {
        id: med.id,
        user_id: med.user_id,
        name: med.name,
        dosage: med.dosage,
        purpose: med.purpose || null,
        frequency: med.frequency,
        times: times
      };
    });

    console.log('Parsed medicines:', parsedMedicines); // Debug

    // Log activity
    await logActivity(userId, 'VIEW_MEDICINES', { count: parsedMedicines.length });

    res.status(200).json({
      message: 'Medicines retrieved successfully',
      medicines: parsedMedicines
    });
  } catch (error) {
    console.error('Get medicines error:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve medicines', 
      details: error.message 
    });
  }
};

// Add new medicine
exports.addMedicine = async (req, res) => {
  try {
    const userId = req.userId;
    const { name, dosage, purpose, frequency, times } = req.body;

    console.log('Adding medicine:', { userId, name, dosage, frequency, times }); // Debug

    // Validation
    if (!name || !dosage || !frequency || !times) {
      return res.status(400).json({ error: 'Name, dosage, frequency and times are required' });
    }

    if (!Array.isArray(times)) {
      return res.status(400).json({ error: 'Times must be an array' });
    }

    // Insert medicine
    const [result] = await db.query(
      'INSERT INTO medicines (user_id, name, dosage, purpose, frequency, times) VALUES (?, ?, ?, ?, ?, ?)',
      [userId, name, dosage, purpose || null, frequency, JSON.stringify(times)]
    );

    console.log('Medicine inserted with ID:', result.insertId); // Debug

    // Log activity
    await logActivity(userId, 'ADD_MEDICINE', { 
      medicine_id: result.insertId, 
      name, 
      dosage, 
      frequency 
    });

    res.status(201).json({
      message: 'Medicine added successfully',
      medicine: {
        id: result.insertId,
        user_id: userId,
        name,
        dosage,
        purpose: purpose || null,
        frequency,
        times
      }
    });
  } catch (error) {
    console.error('Add medicine error:', error);
    res.status(500).json({ 
      error: 'Failed to add medicine', 
      details: error.message 
    });
  }
};

// Update medicine
exports.updateMedicine = async (req, res) => {
  try {
    const userId = req.userId;
    const medicineId = req.params.id;
    const { name, dosage, purpose, frequency, times } = req.body;

    // Check if medicine exists
    const [existing] = await db.query(
      'SELECT * FROM medicines WHERE id = ? AND user_id = ?',
      [medicineId, userId]
    );

    if (existing.length === 0) {
      return res.status(404).json({ error: 'Medicine not found' });
    }

    // Validation
    if (!name || !dosage || !purpose || !frequency || !times) {
      return res.status(400).json({ error: 'Name, dosage, purpose, frequency and times are required' });
    }

    if (!Array.isArray(times)) {
      return res.status(400).json({ error: 'Times must be an array' });
    }

    // Update medicine
    await db.query(
      'UPDATE medicines SET name = ?, dosage = ?, purpose = ?, frequency = ?, times = ? WHERE id = ? AND user_id = ?',
      [name, dosage, purpose || null, frequency, JSON.stringify(times), medicineId, userId]
    );

    // Log activity
    await logActivity(userId, 'UPDATE_MEDICINE', { 
      medicine_id: medicineId,
      old_name: existing[0].name,
      new_name: name
    });

    res.status(200).json({
      message: 'Medicine updated successfully',
      medicine: {
        id: parseInt(medicineId),
        user_id: userId,
        name,
        dosage,
        purpose: purpose || null,
        frequency,
        times
      }
    });
  } catch (error) {
    console.error('Update medicine error:', error);
    res.status(500).json({ 
      error: 'Failed to update medicine', 
      details: error.message 
    });
  }
};

// Delete medicine
exports.deleteMedicine = async (req, res) => {
  try {
    const userId = req.userId;
    const medicineId = req.params.id;

    // Check if medicine exists
    const [existing] = await db.query(
      'SELECT * FROM medicines WHERE id = ? AND user_id = ?',
      [medicineId, userId]
    );

    if (existing.length === 0) {
      return res.status(404).json({ error: 'Medicine not found' });
    }

    // Delete medicine
    await db.query(
      'DELETE FROM medicines WHERE id = ? AND user_id = ?',
      [medicineId, userId]
    );

    // Log activity
    await logActivity(userId, 'DELETE_MEDICINE', { 
      medicine_id: medicineId,
      medicine_name: existing[0].name
    });

    res.status(200).json({
      message: 'Medicine deleted successfully'
    });
  } catch (error) {
    console.error('Delete medicine error:', error);
    res.status(500).json({ 
      error: 'Failed to delete medicine', 
      details: error.message 
    });
  }
};