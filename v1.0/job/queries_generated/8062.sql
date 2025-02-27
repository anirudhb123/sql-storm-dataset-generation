SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
    COUNT(DISTINCT ci.id) AS cast_count,
    AVG(mi.info) AS avg_movie_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.id, t.id
ORDER BY 
    t.production_year DESC, a.name;
