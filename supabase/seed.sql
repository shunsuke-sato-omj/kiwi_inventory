-- 開発用の初期データ（ローカル/開発環境でのみ実行してください）
insert into public.varieties (name, standard_ripening_days_min, standard_ripening_days_max) values
  ('香緑', 7, 10),
  ('ヘイワード', 7, 10)
on conflict (name) do nothing;

insert into public.fields (name, location) values
  ('第1区画', '福島市内'),
  ('第2区画', '福島市内')
on conflict do nothing;

insert into public.storage_locations (name) values
  ('畑横倉庫'),
  ('冷蔵庫A'),
  ('自宅保管')
on conflict do nothing;
