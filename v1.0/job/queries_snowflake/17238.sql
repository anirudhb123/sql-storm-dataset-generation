
SELECT 
    t.title, 
    a.name AS actor_name, 
    c.note AS cast_note 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    cast_info ci ON mc.movie_id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
LEFT JOIN 
    cast_info c ON ci.movie_id = c.movie_id AND ci.person_id = c.person_id 
WHERE 
    t.production_year = 2022 
GROUP BY 
    t.title, a.name, c.note 
ORDER BY 
    t.title;
