# Impostor Word 🎭

A real-time multiplayer social deduction game built for mobile and web, where players must identify the impostor before time runs out.

Players join private rooms using room codes, receive hidden words, discuss clues in real time, and vote to eliminate the suspected impostor. Innocent players share similar words, while the impostor must blend in without knowing the actual word.

Built with a modern cross-platform architecture using Flutter, React, PartyKit, and WebSockets for seamless low-latency gameplay.

---

## ✨ Features

- 🎮 Real-time multiplayer gameplay
- 📱 Cross-platform support (Flutter + React)
- 🔌 Live WebSocket synchronization using PartyKit
- 🏠 Private room creation with room codes
- 🗳️ Real-time voting system
- ⏱️ Timed discussion and voting rounds
- 💬 Live in-game chat/discussion flow
- 🎭 Hidden role & secret word mechanics
- 📚 Dynamic word database powered by Supabase
- 🧠 Category & difficulty-based word filtering
- ⚡ Low-latency game state management

---

## 🛠️ Tech Stack

### Mobile
- Flutter

### Web
- React

### Backend / Multiplayer
- PartyKit
- Real-Time WebSockets

### Database
- Supabase

---

## 🧩 Architecture Highlights

- Implemented event-driven multiplayer synchronization using WebSockets.
- Designed scalable room-based game state management for live sessions.
- Replaced hardcoded game words with a dynamic Supabase-powered content system containing 1000+ curated word pairs.
- Enabled runtime filtering for categories and difficulty levels without requiring app redeployment.

---

## 👨‍💻 My Contribution

Focused on building the complete mobile application in Flutter, including:

- Multiplayer game flow
- Real-time socket integration
- Lobby & room management
- Voting system
- Responsive gameplay UI
- Timer-based interactions
- Game state handling

The web platform was developed collaboratively by my teammate using React.

---

## 🚀 Gameplay Flow

1. Create or join a private room
2. Wait for players to join
3. Receive your secret word
4. Discuss clues with other players
5. Identify suspicious behavior
6. Vote for the impostor
7. Reveal results and winner

---

## 🎯 Goal

The innocent players must identify the impostor.

The impostor must survive by blending into the discussion without knowing the actual word.
