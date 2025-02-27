SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    pi.info AS actor_info,
    COUNT(*) AS total_roles
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
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    a.name NOT LIKE '%test%'
    AND t.production_year >= 2000
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, co.name, k.keyword, pi.info
ORDER BY 
    total_roles DESC, a.name ASC;
