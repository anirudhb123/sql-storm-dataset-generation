SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.note AS cast_note,
    co.name AS company_name,
    mt.kind AS company_type,
    w.keyword AS movie_keyword,
    m.info AS movie_info,
    y.production_year
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword w ON mw.keyword_id = w.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    aka_title y ON t.id = y.movie_id
WHERE 
    t.production_year >= 2000
    AND mt.kind IN ('Distributor', 'Production')
    AND w.keyword LIKE '%action%'
ORDER BY 
    y.production_year DESC, 
    a.name;
