SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mk.keyword) AS associated_keywords,
    STRING_AGG(DISTINCT ci.note, ', ') AS roles,
    ii.info AS additional_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ii ON mi.info_type_id = ii.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, ak.name, ii.info
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 AND 
    COUNT(DISTINCT mk.keyword) > 3
ORDER BY 
    t.title, ak.name;
