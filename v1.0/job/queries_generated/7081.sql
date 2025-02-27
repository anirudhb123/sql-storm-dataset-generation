SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT pi.info ORDER BY pi.info_type_id) AS person_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 1990 AND 2020
AND 
    ci.nr_order < 3
GROUP BY 
    t.title, a.name
ORDER BY 
    production_company_count DESC, movie_title ASC;
