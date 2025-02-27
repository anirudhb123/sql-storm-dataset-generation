SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS role_note,
    c.name AS company_name,
    kt.keyword AS movie_keyword
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    aka_title AS t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies AS mc ON t.movie_id = mc.movie_id
JOIN 
    company_name AS c ON mc.company_id = c.id
JOIN 
    movie_keyword AS mk ON t.movie_id = mk.movie_id
JOIN 
    keyword AS kt ON mk.keyword_id = kt.id
WHERE 
    a.name IS NOT NULL
    AND t.title IS NOT NULL
    AND c.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name ASC;
