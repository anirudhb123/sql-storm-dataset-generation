SELECT a.id as aka_id,
       a.name as aka_name,
       t.title as movie_title,
       c.name as character_name,
       p.info as person_info,
       ct.kind as cast_type,
       cn.name as company_name,
       m.info as movie_info
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN char_name c ON c.imdb_index = a.imdb_index
JOIN person_info p ON a.person_id = p.person_id
JOIN role_type rt ON ci.role_id = rt.id
JOIN comp_cast_type ct ON ci.person_role_id = ct.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN movie_info m ON t.id = m.movie_id
WHERE t.production_year > 2000
  AND cn.country_code = 'USA'
  AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY t.production_year DESC, a.name ASC
LIMIT 100;
