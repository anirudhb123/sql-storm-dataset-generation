SELECT a.name, t.title, c.note 
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN company_name cn ON ci.movie_id = cn.imdb_id
WHERE t.production_year = 2023;
