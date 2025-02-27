SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS role_note,
    c.kind AS comp_cast_type,
    m.company_id,
    m.note AS movie_note,
    mi.info AS movie_info
FROM 
    title AS t
JOIN 
    aka_title AS at ON t.id = at.movie_id
JOIN 
    cast_info AS ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS m ON t.id = m.movie_id
JOIN 
    comp_cast_type AS c ON ci.person_role_id = c.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
