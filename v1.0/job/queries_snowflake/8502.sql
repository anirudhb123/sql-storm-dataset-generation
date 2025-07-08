
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT p.id) AS num_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%Drama%'
GROUP BY 
    a.name, t.title, ct.kind, k.keyword
ORDER BY 
    num_roles DESC, a.name ASC;
