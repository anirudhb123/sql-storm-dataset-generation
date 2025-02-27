SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    ct.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON at.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    at.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, ct.kind
HAVING 
    company_count > 1
ORDER BY 
    actor_name, movie_title;
