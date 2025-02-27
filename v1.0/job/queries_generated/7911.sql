SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    COUNT(mk.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(mk.keyword) > 0
ORDER BY 
    keyword_count DESC, movie_title ASC;
