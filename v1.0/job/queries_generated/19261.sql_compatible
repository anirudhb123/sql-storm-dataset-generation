
SELECT 
    t.title, 
    a.name AS actor_name, 
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year = 2022
GROUP BY 
    t.title, a.name
ORDER BY 
    t.title;
