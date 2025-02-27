SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    COUNT(k.keyword) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 AND 
    a.name IS NOT NULL AND 
    ct.kind IS NOT NULL
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    keyword_count DESC, movie_title ASC;
