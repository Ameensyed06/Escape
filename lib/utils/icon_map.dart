import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Maps a free-text [iconKey] (stored with goals / apps) to a Material Symbol.
IconData iconForKey(String key) {
  switch (key) {
    case 'book':
      return Symbols.menu_book_rounded;
    case 'water':
      return Symbols.water_drop_rounded;
    case 'meditation':
      return Symbols.self_improvement_rounded;
    case 'sleep':
      return Symbols.bedtime_rounded;
    case 'run':
      return Symbols.directions_run_rounded;
    case 'code':
      return Symbols.code_rounded;
    case 'journal':
      return Symbols.edit_note_rounded;
    case 'no_junk':
      return Symbols.no_food_rounded;
    case 'walk':
      return Symbols.directions_walk_rounded;
    case 'sun':
      return Symbols.wb_sunny_rounded;
    case 'instagram':
      return Symbols.photo_camera_rounded;
    case 'tiktok':
      return Symbols.music_note_rounded;
    case 'youtube':
      return Symbols.smart_display_rounded;
    case 'twitter':
      return Symbols.tag_rounded;
    case 'games':
      return Symbols.sports_esports_rounded;
    case 'reddit':
      return Symbols.forum_rounded;
    case 'browser':
      return Symbols.public_rounded;
    case 'messages':
      return Symbols.chat_rounded;
    case 'mail':
      return Symbols.mail_rounded;
    case 'shopping':
      return Symbols.shopping_bag_rounded;
    case 'flame':
      return Symbols.local_fire_department_rounded;
    case 'target':
      return Symbols.target_rounded;
    case 'trophy':
      return Symbols.trophy_rounded;
    case 'dumbbell':
      return Symbols.fitness_center_rounded;
    default:
      return Symbols.check_circle_rounded;
  }
}

/// Simple curated list of icon keys offered in pickers.
const goalIconKeys = [
  'book',
  'water',
  'meditation',
  'sleep',
  'run',
  'code',
  'journal',
  'no_junk',
  'walk',
  'sun',
  'flame',
  'target',
];

const appIconKeys = [
  'instagram',
  'tiktok',
  'youtube',
  'twitter',
  'games',
  'reddit',
  'browser',
  'messages',
  'mail',
  'shopping',
];
