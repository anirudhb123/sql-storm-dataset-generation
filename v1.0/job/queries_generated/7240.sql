SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS associated_keywords,
    c.kind AS company_type,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND c.country_code = 'USA'
GROUP BY 
    t.id, ak.name, c.kind, mi.info
ORDER BY 
    t.title, ak.name;
