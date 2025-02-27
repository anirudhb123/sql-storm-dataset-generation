
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    COUNT(DISTINCT mi.info) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    a.imdb_index IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    info_count DESC, actor_name ASC;
