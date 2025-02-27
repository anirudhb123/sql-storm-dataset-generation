
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    COUNT(mk.id) AS keyword_count,
    STRING_AGG(k.keyword, ',') AS keywords,
    AVG(LENGTH(mi.info)) AS average_info_length
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(mk.id) > 5
ORDER BY 
    average_info_length DESC, movie_title ASC;
