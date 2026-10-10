ПАНЕЛИ ИДОРАКУНИИ — ВИКТОРИНАИ ИСЛОМӢ

1. index.html-ро дар браузер кушоед (ё дар hosting-и статикӣ ҷойгир кунед).
2. Project URL-и лоиҳаи Supabase: https://qwixhhfwnnyryxowsfye.supabase.co
3. Publishable key-ро худатон ба майдон гузоред.
4. Бо почтаи электронӣ ва пароли корбаре, ки дар Supabase Authentication сохтаед, ворид шавед.
5. UID-и ҳамин корбар бояд дар public.admins бошад.

Агар source_text ҳанӯз ба questions илова нашуда бошад, дар Supabase SQL Editor иҷро кунед:
ALTER TABLE public.questions ADD COLUMN IF NOT EXISTS source_text text;

Амният:
- Ин сайт паролро дар коди оммавӣ нигоҳ намедорад. Воридшавӣ тавассути Supabase Auth аст.
- Пароли фиристодашуда дар чат дигар набояд ҳамчун пароли доимӣ истифода шавад; онро дар Supabase иваз кунед.
- Танҳо Publishable key ё anon/public истифода кунед. SECRET ва service_role-ро ҳеҷ гоҳ ба HTML нагузоред.
- Ин ZIP сайтро худкор дар интернет нашр намекунад; барои URL-и оммавӣ онро ба hosting-и статикӣ бор кардан лозим аст.
