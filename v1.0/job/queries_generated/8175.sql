EXPLAIN ANALYZE 
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(DISTINCT m.id) AS other_movies_count,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
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
    ct.kind IS NOT NULL
GROUP BY 
    t.id, a.name, ct.kind
ORDER BY 
    COUNT(DISTINCT m.id) DESC, t.title;
