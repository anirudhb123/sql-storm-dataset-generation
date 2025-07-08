SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    n.name AS person_name,
    ci.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    title AS t ON c.movie_id = t.id
JOIN 
    name AS n ON a.person_id = n.imdb_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
