SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS comp_cast_type,
    y.keyword AS movie_keyword,
    p.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mkt ON t.id = mkt.movie_id
JOIN 
    keyword y ON mkt.keyword_id = y.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL 
ORDER BY 
    a.name, t.production_year;
