SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    co.name AS company_name,
    ti.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT mi.movie_id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND k.keyword ILIKE '%action%'
GROUP BY 
    t.title, a.name, c.kind, co.name, ti.info, k.keyword
ORDER BY 
    total_movies DESC, t.title ASC
LIMIT 100;
