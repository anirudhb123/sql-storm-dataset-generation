SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.person_role_id, 
    p.info AS person_info,
    ky.keyword
FROM 
    title t
JOIN 
    aka_title ak ON t.id = ak.movie_id
JOIN 
    cast_info c ON ak.movie_id = c.movie_id
JOIN 
    name p ON c.person_id = p.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ky ON mk.keyword_id = ky.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
