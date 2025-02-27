
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT cn.name, ',' ORDER BY cn.name ASC) AS companies,
    STRING_AGG(DISTINCT kw.keyword, ',' ORDER BY kw.keyword ASC) AS keywords,
    pi.info AS person_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    ak.name, t.title, t.production_year, pi.info
ORDER BY 
    t.production_year DESC, ak.name;
