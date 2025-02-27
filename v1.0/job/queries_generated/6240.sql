SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_type,
    mk.keyword AS movie_keyword,
    COUNT(mk.id) AS keyword_count,
    COUNT(DISTINCT ci.person_id) AS distinct_actors,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, a.name, c.kind, mk.keyword
HAVING 
    COUNT(mk.id) > 1
ORDER BY 
    keyword_count DESC, distinct_actors DESC;
