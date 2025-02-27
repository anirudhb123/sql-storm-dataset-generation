SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    COUNT(DISTINCT mc.movie_id) AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    pi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%bio%')
    AND t.production_year > 2000
GROUP BY 
    a.name, t.title, c.kind, k.keyword, pi.info
ORDER BY 
    movie_count DESC, a.name ASC;
