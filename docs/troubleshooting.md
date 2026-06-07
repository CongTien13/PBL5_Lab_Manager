# Troubleshooting Guide

## Overview

This guide covers common issues and their solutions for the PBL5 Lab Manager system.

## Mobile App Issues

### Authentication Errors

#### "No user found with this email"

**Cause**: User account not created in Firestore.

**Solution**:
1. Check Firebase Authentication Console
2. Verify user was created during registration
3. Check Firestore `users` collection

#### "Wrong password"

**Cause**: Invalid credentials.

**Solution**:
1. Reset password in Firebase Auth
2. Re-register if account corrupted

### Device Loading Errors

#### "Failed to load devices"

**Cause**: Firestore connection issue or network error.

**Solution**:
```dart
// Check network connection
final connectivity = await FirebaseFirestore.instance.settings;
// Ensure persistence enabled
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
```

#### "Device status not updating"

**Cause**: Real-time listener not working.

**Solution**:
```dart
// Re-subscribe to device stream
context.read<DeviceCubit>().watchDevices();
```

### Booking Errors

#### "Booking time conflict"

**Cause**: Another booking exists at the same time.

**Solution**: Select a different time slot.

#### "Cannot create booking"

**Cause**: Device unavailable or not approved.

**Solution**:
1. Check device status in Firestore
2. Contact admin to approve booking

## AI Model Issues

### Face Detection Errors

#### "No face detected"

**Cause**: Face not aligned or poor lighting.

**Solution**:
1. Ensure face is centered
2. Improve lighting
3. Remove accessories (glasses, hat)
4. Check camera resolution

#### "Multiple faces detected"

**Cause**: Multiple people in frame.

**Solution**: Ensure only one person in camera frame.

### Embedding Errors

#### "Embedding failed"

**Cause**: Face not detected or model error.

**Solution**:
```bash
# Check face_db.npy
python -c "import numpy as np; db = np.load('weights/face_db.npy', allow_pickle=True).item(); print(list(db.keys()))"
```

#### "embeddingStatus: failed"

**Cause**: Face images not processable.

**Solution**:
1. Upload new face images
2. Ensure clear, well-lit photos
3. Try different angles

### SSH Upload Errors

#### "Connection refused"

**Cause**: Raspberry Pi not reachable.

**Solution**:
```bash
# Check SSH connection
ssh pi@172.20.10.2

# Verify IP
ping 172.20.10.2
```

#### "Authentication failed"

**Cause**: Wrong SSH credentials.

**Solution**:
```python
# Update credentials in main.py
RASPBERRY_PASSWORD = "correct_password"
```

## Raspberry Pi Issues

### Hardware Errors

#### "Cannot open camera"

**Cause**: Camera not detected or in use.

**Solution**:
```bash
# Check camera
ls /dev/video0

# Release camera
sudo rmmod uvcvideo
sudo modprobe uvcvideo
```

#### "GPIO not working"

**Cause**: Not running as root or GPIO error.

**Solution**:
```bash
# Run with sudo
sudo python3 scan_listener.py

# Check GPIO permissions
sudo usermod -a -G gpio pi
```

### Recognition Errors

#### "Unknown user always"

**Cause**:
1. Face database not loaded
2. Wrong threshold
3. Poor face capture

**Solution**:
```bash
# Check face_db.npy exists
ls -la weights/face_db.npy

# Update threshold in main.py
THRESHOLD = 0.1  # Increase threshold
```

#### "Low recognition score"

**Cause**: Face capture quality.

**Solution**:
1. Improve lighting
2. Adjust camera position
3. Increase scan duration
4. Re-register user with more photos

### Connection Errors

#### "Firebase connection failed"

**Cause**: Network or credentials issue.

**Solution**:
```bash
# Test Firebase connection
python3 -c "import firebase_admin; print('OK')"

# Check service account
cat serviceAccountKey.json | python3 -m json.tool
```

#### "Firestore listener not working"

**Cause**: Query error or network.

**Solution**:
```python
# Add error handling
def on_snapshot(col_snapshot, changes, read_time):
    try:
        for change in changes:
            # process change
    except Exception as e:
        print(f"Error: {e}")
```

## Database Issues

### Firestore Errors

#### "PERMISSION_DENIED"

**Cause**: Security rules blocking access.

**Solution**:
1. Check Firestore security rules
2. Verify user authentication
3. Check document permissions

#### "NOT_FOUND"

**Cause**: Document doesn't exist.

**Solution**:
```dart
// Check if document exists
final doc = await FirebaseFirestore.instance
    .collection('devices')
    .doc('dev01')
    .get();

if (!doc.exists) {
  // Create document
}
```

### Data Inconsistencies

#### "Device status mismatch"

**Cause**: Race condition or stale data.

**Solution**:
```dart
// Force refresh
await FirebaseFirestore.instance
    .collection('devices')
    .doc(deviceId)
    .update({'updatedAt': FieldValue.serverTimestamp()});
```

## Network Issues

### Connection Problems

#### "Connection timeout"

**Cause**: Network unreachable.

**Solution**:
```bash
# Check network
ping 172.20.10.2
ping google.com

# Check firewall
sudo ufw status
```

#### "SSH connection slow"

**Cause**: DNS resolution.

**Solution**:
```bash
# Edit /etc/ssh/sshd_config
UseDNS no

# Restart SSH
sudo systemctl restart ssh
```

## Performance Issues

### Slow Response

#### "Mobile app slow"

**Cause**: Too many Firestore reads.

**Solution**:
1. Implement pagination
2. Use caching
3. Optimize queries

#### "Face recognition slow"

**Cause**: CPU-based inference.

**Solution**:
1. Use GPU if available
2. Reduce scan duration
3. Optimize model

### High Memory Usage

#### "Out of memory"

**Cause**: Large face database.

**Solution**:
1. Reduce embedding storage
2. Clean up temporary files
3. Restart services

## Logging

### Enable Debug Logging

#### Mobile App

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### Raspberry Pi

Add to `scan_listener.py`:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s %(levelname)s %(message)s',
    handlers=[
        logging.FileHandler('/var/log/pbl5.log'),
        logging.StreamHandler()
    ]
)
```

## Diagnostic Commands

### Check System Status

```bash
# Check AI model service
python3 -c "import torch; print('PyTorch:', torch.__version__)"

# Check Firebase connection
python3 -c "import firebase_admin; print('Firebase OK')"

# Check face database
python3 -c "import numpy as np; db = np.load('weights/face_db.npy', allow_pickle=True).item(); print('Users:', len(db))"
```

### Check Network

```bash
# Check connectivity
ping -c 4 google.com

# Check Raspberry Pi
ping -c 4 172.20.10.2

# Check ports
nmap -p 22 172.20.10.2
```

### Check Firebase

```bash
# Check Firebase CLI
firebase projects:list

# Check Firestore indexes
firebase firestore:indexes
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| Network is unreachable | No internet | Check network |
| Permission denied | Auth error | Re-authenticate |
| Document not found | Data missing | Create document |
| Invalid email | Format error | Check email format |
| Weak password | Security | Use stronger password |
| Device in use | Conflict | Wait or cancel booking |

## Get Help

### Logs to Collect

1. Mobile app logs (adb logcat)
2. Raspberry Pi logs (journalctl)
3. Firebase console logs
4. Network diagnostics

### Report Issue

Include:
1. Error message/ID
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Logs
6. Environment details

## Prevention

### Best Practices

1. **Regular Backups**: Schedule automatic backups
2. **Monitor Logs**: Check logs daily
3. **Update Dependencies**: Keep packages updated
4. **Test Regularly**: Run integration tests
5. **Document Changes**: Track configuration changes

### Monitoring Setup

Create health check script:

```python
#!/usr/bin/env python3
import firebase_admin
from firebase_admin import credentials, firestore

def health_check():
    try:
        db = firestore.client()
        doc = db.collection('devices').document('dev01').get()
        return doc.exists
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

if __name__ == '__main__':
    print("OK" if health_check() else "FAIL")
```