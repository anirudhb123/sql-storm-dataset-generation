SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = at.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, ak.name;
