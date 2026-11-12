# 0003 - Server-side Moodle synchronisation and notifications

Status: proposed, deferred
Related: 0002 (sign-in, account linking, no stored Moodle tokens)
Scope: deadline notifications while the app is closed

## Context

Decision 0002 keeps Moodle API tokens on the device. The server stores identifiers only. This
means the server cannot read Moodle data on its own, so it cannot detect new or changed deadlines
while the app is closed.

Three responsibilities are easy to confuse. They are separate:

1. **Delivery:** Firebase Cloud Messaging (FCM) sends a push notification to a device. FCM does
   not read Moodle and does not know whether a deadline changed.
2. **Change detection:** something must read Moodle data and compare it with the previous state.
3. **Scheduling:** something must decide when to check and when to notify.

FCM covers only the first. Detection and scheduling need a process that can reach Moodle.

## Options

### A. Device-driven synchronisation

The Flutter app fetches Moodle data and schedules local notifications. FCM is not needed for
this.

- Works while the app is open, and with OS background tasks where the system allows them.
- No Moodle tokens leave the device. This keeps 0002 unchanged.
- Timing is not guaranteed. Android and iOS can delay or stop background work, and users can
  disable it. Notifications can arrive late or not at all.

### B. Server-driven synchronisation

A background worker on the server periodically calls Moodle for each connected student, detects
new or changed deadlines, and sends notifications through FCM.

- Reliable timing, and notifications work while the app is closed.
- Requires the server to hold a Moodle API token for each student, or to obtain one on demand.
- Holding tokens conflicts with 0002 and needs its own security design.
- A worker that holds many students' tokens is a high-value target. A breach exposes every
  student's Moodle access.

## Decision

Keep Moodle tokens on the device until a separate security and synchronisation decision is
approved. Option A is the only approved path for now.

## Requirements before approving option B

- Encryption at rest with a key held outside the database. Plan key rotation.
- A written retention rule: how long tokens are kept, and when they are deleted on sign-out or
  account deletion.
- A revocation path, so a token can be invalidated when a student disconnects.
- Least privilege: request only the Moodle functions the worker needs, and confirm that the
  school's web service allows them.
- Consent: students are told that the server will read their Moodle data in the background.
- The same SSRF protections as 0002 for every outgoing Moodle request.
- Logging rules that never record tokens or assignment content.
- A review by someone who has not written the worker.

## Consequences for the app today

| Feature | Possible under option A |
|---|---|
| Fetch courses while the app is open | Yes |
| Fetch assignments and grades | Yes |
| Offline access with a local cache | Yes |
| Notifications while the app is open | Yes |
| Notifications while the app is closed | Not reliably |
| Background sync | Limited by OS restrictions |
