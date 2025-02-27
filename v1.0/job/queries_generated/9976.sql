SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    cc.note AS cast_note,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    x.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info cc ON a.person_id = cc.person_id
JOIN 
    title t ON cc.movie_id = t.id
JOIN 
    movie_info x ON t.id = x.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON cc.role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, cc.note, x.info
ORDER BY 
    COUNT(DISTINCT k.keyword) DESC, t.production_year ASC;
