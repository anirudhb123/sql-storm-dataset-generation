SELECT 
    t.title AS movie_title,
    co.name AS company_name,
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
    MIN(m.produced_year) AS first_production_year,
    COUNT(DISTINCT c.person_id) AS actor_count
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, co.name, ak.name
HAVING 
    COUNT(DISTINCT c.person_id) >= 5
ORDER BY 
    first_production_year DESC, movie_title ASC;
