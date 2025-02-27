SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS actor_info,
    MAX(m.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    title m ON t.id = m.id
WHERE 
    t.production_year > 2000 
AND 
    c.kind LIKE '%Film%'
GROUP BY 
    a.name, t.title, c.kind, k.keyword, pi.info
ORDER BY 
    latest_movie_year DESC, actor_name ASC;
