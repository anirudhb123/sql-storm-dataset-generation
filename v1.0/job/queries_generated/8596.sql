SELECT 
    a.name AS actor_name, 
    at.title AS movie_title, 
    at.production_year, 
    GROUP_CONCAT(DISTINCT c.kind SEPARATOR ', ') AS comp_types,
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS movie_keywords,
    COUNT(mi.info_type_id) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    at.production_year >= 2000
GROUP BY 
    a.name, at.title, at.production_year
ORDER BY 
    at.production_year DESC, a.name ASC;
