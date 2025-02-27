
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    t.production_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    t.title,
    a.name,
    ct.kind,
    t.production_year,
    k.keyword
ORDER BY 
    t.production_year DESC, 
    t.title ASC;
