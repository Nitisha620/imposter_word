// ─── Data ────────────────────────────────────────────────────────────────────

import '../models/rule.dart';

const kRules = [
  Rule(
    '🎯',
    'The Goal',
    'Innocents find who has a different word. The imposter must blend in without getting caught.',
  ),
  Rule(
    '🔑',
    'Your Word',
    'Each player privately sees their secret word. Innocents all get the same word. The imposter gets a similar but different one.',
  ),
  Rule(
    '💬',
    'Discussion',
    'Take turns describing your word without saying it directly. Listen carefully — someone\'s description might not quite fit!',
  ),
  Rule(
    '🗳️',
    'Voting',
    'Everyone votes for who they think is the imposter. Most votes gets eliminated.',
  ),
  Rule(
    '🏆',
    'Winning',
    'Innocents win by eliminating all imposters. Imposters win if they survive to equal the innocents.',
  ),
  Rule(
    '😈',
    'Imposter Knows',
    'You see the IMPOSTER label and get a different word. Describe carefully and blend in.',
  ),
  Rule(
    '🤫',
    'Secret Mode',
    'You get a slightly different word but no label. You might accidentally give yourself away!',
  ),
  Rule(
    '🫥',
    'Blind Mode',
    'You see no word at all. Listen to others and bluff your way through discussion.',
  ),
];
