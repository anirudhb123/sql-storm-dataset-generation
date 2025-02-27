
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    pi.info AS personal_info,
    COUNT(DISTINCT c.id) AS cast_count
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type AS c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info AS pi ON a.person_id = pi.person_id
WHERE 
    t.production_year > 2000 
    AND k.keyword IS NOT NULL 
    AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, pi.info
ORDER BY 
    t.production_year DESC,
    actor_name ASC;
