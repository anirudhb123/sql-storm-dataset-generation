SELECT 
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    AVG(pi.info) AS avg_rating
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title ti ON ci.movie_id = ti.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON ti.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    ti.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, ti.title, ti.production_year, ct.kind
ORDER BY 
    avg_rating DESC
LIMIT 10;
