import {
  BookOpen,
  Droplet,
  Sparkles,
  Moon,
  Footprints,
  Code2,
  PenLine,
  Ban,
  Sun,
  Flame,
  Target,
  Camera,
  Music2,
  Clapperboard,
  Hash,
  Gamepad2,
  MessageCircle,
  Globe,
  MessageSquare,
  Mail,
  ShoppingBag,
  Trophy,
  Dumbbell,
  CheckCircle2,
  type LucideIcon,
} from 'lucide-react';

// Mirrors lib/utils/icon_map.dart — maps a free-text iconKey to an icon
// component. lucide-react doesn't ship trademarked app logos, so social app
// entries use neutral stand-ins (camera/note/clapperboard/hash) instead of
// the real brand marks.
const ICONS: Record<string, LucideIcon> = {
  book: BookOpen,
  water: Droplet,
  meditation: Sparkles,
  sleep: Moon,
  run: Footprints,
  code: Code2,
  journal: PenLine,
  no_junk: Ban,
  walk: Footprints,
  sun: Sun,
  flame: Flame,
  target: Target,
  instagram: Camera,
  tiktok: Music2,
  youtube: Clapperboard,
  twitter: Hash,
  games: Gamepad2,
  reddit: MessageCircle,
  browser: Globe,
  messages: MessageSquare,
  mail: Mail,
  shopping: ShoppingBag,
  trophy: Trophy,
  dumbbell: Dumbbell,
};

export function iconForKey(key: string): LucideIcon {
  return ICONS[key] ?? CheckCircle2;
}

export const goalIconKeys = [
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

export const appIconKeys = [
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
