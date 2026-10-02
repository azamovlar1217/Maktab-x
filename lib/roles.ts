export const roles = ["admin", "director", "teacher", "student", "parent", "cook", "super_admin"] as const;
export type AppRole = (typeof roles)[number];

export const roleLabels: Record<AppRole, string> = {
  admin: "Tizim administratori",
  director: "Maktab direktori",
  teacher: "O‘qituvchi",
  student: "O‘quvchi",
  parent: "Ota-ona",
  cook: "Oshxona xodimi",
  super_admin: "Platforma super-admini",
};

export const navigation: Record<AppRole, { label: string; href: string }[]> = {
  student: [
    { label: "Bosh sahifa", href: "/portal" }, { label: "Kundalik va baholar", href: "/portal/grades" },
    { label: "Dars jadvali", href: "/portal/schedule" }, { label: "Uy vazifalari", href: "/portal/homework" },
    { label: "Davomat", href: "/portal/attendance" }, { label: "AI Ustoz", href: "/portal/tutor" },
    { label: "X Coin", href: "/portal/rewards" }, { label: "Reyting", href: "/portal/leaderboard" },
    { label: "Kitoblar", href: "/portal/library" }, { label: "O‘yinli darslar", href: "/portal/lessons" },
    { label: "Maktab hamjamiyati", href: "/portal/community" }, { label: "Xabarlar", href: "/portal/messages" }, { label: "Bildirishnomalar", href: "/portal/notifications" },
  ],
  teacher: [
    { label: "Bosh sahifa", href: "/portal" }, { label: "Sinflarim", href: "/portal/classes" },
    { label: "O‘quvchilar", href: "/portal/students" }, { label: "Dars jadvali", href: "/portal/schedule" },
    { label: "Uy vazifalari", href: "/portal/homework" }, { label: "Baholar", href: "/portal/grades" },
    { label: "Davomat", href: "/portal/attendance" }, { label: "E’lonlar", href: "/portal/announcements" },
    { label: "Kitoblar", href: "/portal/library" }, { label: "Mini darslar", href: "/portal/lessons" },
    { label: "Hamjamiyat", href: "/portal/community" }, { label: "Xabarlar", href: "/portal/messages" },
  ],
  parent: [
    { label: "Bosh sahifa", href: "/portal" }, { label: "Farzandlarim", href: "/portal/children" },
    { label: "Baholar", href: "/portal/grades" }, { label: "Dars jadvali", href: "/portal/schedule" },
    { label: "Uy vazifalari", href: "/portal/homework" }, { label: "Davomat", href: "/portal/attendance" },
    { label: "E’lonlar", href: "/portal/announcements" }, { label: "Kitoblar", href: "/portal/library" },
    { label: "Hamjamiyat", href: "/portal/community" }, { label: "Xabarlar", href: "/portal/messages" },
  ],
  director: [
    { label: "Bosh sahifa", href: "/portal" }, { label: "O‘quvchilar", href: "/portal/students" },
    { label: "O‘qituvchilar", href: "/portal/teachers" }, { label: "Sinflar", href: "/portal/classes" },
    { label: "Fanlar", href: "/portal/subjects" }, { label: "Dars jadvali", href: "/portal/schedule" },
    { label: "Davomat", href: "/portal/attendance" }, { label: "E’lonlar", href: "/portal/announcements" },
    { label: "CoinShop", href: "/portal/rewards" }, { label: "Oshxona", href: "/portal/cafeteria" },
    { label: "Kitoblar", href: "/portal/library" }, { label: "Mini darslar", href: "/portal/lessons" },
    { label: "Hamjamiyat", href: "/portal/community" }, { label: "Hisobotlar", href: "/portal/reports" }, { label: "Audit jurnali", href: "/portal/audit" },
  ],
  admin: [
    { label: "Bosh sahifa", href: "/portal" }, { label: "Maktablar", href: "/portal/schools" },
    { label: "Foydalanuvchilar", href: "/portal/users" }, { label: "Rollar va takliflar", href: "/portal/invitations" },
    { label: "Kitoblar", href: "/portal/library" }, { label: "O‘yinli darslar", href: "/portal/lessons" },
    { label: "Hamjamiyat", href: "/portal/community" }, { label: "Tanishuv slaydlari", href: "/portal/tour" }, { label: "Aloqa sahifasi", href: "/portal/contact" }, { label: "Sozlamalar", href: "/portal/settings" }, { label: "Audit jurnali", href: "/portal/audit" },
  ],
  cook: [
    { label: "Oshpaz paneli", href: "/portal/kitchen" }, { label: "CoinShop mahsulotlari", href: "/portal/rewards" },
    { label: "Oshxona", href: "/portal/cafeteria" }, { label: "Bildirishnomalar", href: "/portal/notifications" },
  ],
  super_admin: [
    { label: "Platforma", href: "/portal" }, { label: "Maktablarni ulash", href: "/portal/schools" },
    { label: "Maktab adminlari", href: "/portal/users" }, { label: "Audit jurnali", href: "/portal/audit" },
  ],
};
