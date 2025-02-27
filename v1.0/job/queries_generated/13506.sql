SELECT 
    akn.name AS aka_name,
    mt.title AS movie_title,
    p.name AS person_name,
    ct.kind AS company_type,
    t.production_year,
    w.keyword AS movie_keyword
FROM aka_name akn
JOIN cast_info ci ON akn.person_id = ci.person_id
JOIN aka_title mt ON ci.movie_id = mt.movie_id
JOIN movie_companies mc ON mt.id = mc.movie_id
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN movie_keyword mk ON mt.id = mk.movie_id
JOIN keyword w ON mk.keyword_id = w.id
JOIN title t ON mt.movie_id = t.id
JOIN name p ON akn.person_id = p.imdb_id
WHERE t.production_year > 2000
ORDER BY t.production_year DESC, akn.name;
