SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    k.keyword AS movie_keyword,
    inf.info AS movie_info,
    co.name AS company_name
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    aka_title AS t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS inf ON t.id = inf.movie_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS co ON mc.company_id = co.id
WHERE 
    a.name ILIKE '%Chris%'
    AND t.production_year > 2000
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;