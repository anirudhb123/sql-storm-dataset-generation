SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT c.character_name) AS characters,
    GROUP_CONCAT(DISTINCT p.name) AS companies,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name p ON mc.company_id = p.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000
AND 
    ak.name IS NOT NULL
AND 
    i.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
GROUP BY 
    ak.name, t.title, k.keyword, i.info
ORDER BY 
    t.production_year DESC;
