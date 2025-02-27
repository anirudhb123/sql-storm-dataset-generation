SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.note AS role_note,
    y.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, ak.name;
