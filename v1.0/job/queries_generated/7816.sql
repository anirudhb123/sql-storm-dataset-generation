SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT m.id) AS related_movies_count
FROM 
    aka_title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    title mt ON ml.linked_movie_id = mt.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    related_movies_count DESC, movie_title ASC;
