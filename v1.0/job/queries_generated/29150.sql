SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year AS release_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(pi.info IS NOT NULL) AS avg_person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    a.name IS NOT NULL 
    AND m.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%drama%'
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    m.production_year DESC, total_cast DESC
LIMIT 10;
