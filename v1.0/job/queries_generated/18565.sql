SELECT 
    t.title,
    p.name AS actor_name,
    k.keyword
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name p ON cc.subject_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title;
