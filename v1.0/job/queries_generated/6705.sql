SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    ci.note AS cast_note,
    COUNT(mk.keyword) AS keyword_count,
    GROUP_CONCAT(k.keyword) AS keywords,
    AVG(mi.info) AS average_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
GROUP BY 
    a.name, t.title, c.kind, ci.note
HAVING 
    keyword_count > 0
ORDER BY 
    average_info_length DESC, actor_name ASC;
