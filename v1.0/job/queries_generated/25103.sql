SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    p.info AS person_info,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT c.id) AS cast_count,
    AVG(l.linked_movie_id) AS avg_linked_movies
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info c ON at.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_link l ON t.id = l.movie_id
GROUP BY 
    t.title, a.name, r.role, p.info, m.info, k.keyword
HAVING 
    CAST(AVG(l.linked_movie_id) AS INT) > 1
ORDER BY 
    cast_count DESC, movie_title ASC;
