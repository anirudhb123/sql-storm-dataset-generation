SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    m.company_name AS production_company,
    k.keyword AS movie_keyword,
    mi.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE '%John%'
    AND t.production_year > 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, a.name;
