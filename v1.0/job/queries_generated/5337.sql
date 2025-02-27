SELECT 
    a.name AS actor_name, 
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    COUNT(DISTINCT ca.movie_id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    title t ON ca.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND c.kind = 'Distributor'
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Height')
GROUP BY 
    a.name, t.title, c.kind, k.keyword, pi.info
ORDER BY 
    total_movies DESC, a.name ASC;
