SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    a.name AS aka_name,
    ci.note AS cast_note,
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    cast_info ci
JOIN 
    name n ON ci.person_id = n.id
JOIN 
    aka_name a ON n.id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
GROUP BY 
    n.name, t.title, a.name, ci.note
ORDER BY 
    keyword_count DESC
LIMIT 100;
