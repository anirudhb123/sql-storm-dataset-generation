SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    n.name AS actor_name,
    k.keyword AS movie_keyword
FROM 
    aka_title AT
JOIN 
    title T ON AT.id = T.id
JOIN 
    cast_info C ON AT.movie_id = C.movie_id
JOIN 
    aka_name A ON C.person_id = A.person_id
JOIN 
    name N ON C.person_id = N.id
JOIN 
    movie_keyword MK ON AT.movie_id = MK.movie_id
JOIN 
    keyword K ON MK.keyword_id = K.id
WHERE 
    T.production_year >= 2000
ORDER BY 
    T.production_year DESC, 
    aka_name, 
    movie_title;
