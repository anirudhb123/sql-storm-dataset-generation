SELECT 
    at.title AS movie_title,
    an.name AS actor_name,
    cc.kind AS cast_type,
    mi.info AS movie_info
FROM 
    aka_title at
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    movie_info mi ON at.id = mi.movie_id
WHERE 
    at.production_year > 2000
ORDER BY 
    at.production_year DESC, 
    an.name;
