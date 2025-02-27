SELECT 
    t.title AS movie_title,
    GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    GROUP_CONCAT(DISTINCT comp.name) AS production_companies,
    MAX(year.info) AS info_note
FROM 
    title t
JOIN 
    aka_title ak_title ON t.id = ak_title.movie_id
JOIN 
    aka_name ak ON ak_title.id = ak.id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name comp ON comp.id = mc.company_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN 
    info_type year ON year.id = mi.info_type_id AND year.info = 'Year'
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.id
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    t.production_year DESC;
