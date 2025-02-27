
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.note AS casting_note, 
    m.info AS movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_info m ON cc.movie_id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name LIKE '%Smith%' AND 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.note, m.info, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
