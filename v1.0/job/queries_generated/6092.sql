SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c2.kind AS company_type,
    COALESCE(mi.info, 'Not Available') AS movie_info,
    COUNT(k.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c2 ON mc.company_type_id = c2.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, company_type, mi.info
ORDER BY 
    keyword_count DESC, a.name ASC;
