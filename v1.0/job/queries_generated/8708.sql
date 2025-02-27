SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    pc.info AS production_company,
    ti.info AS additional_info 
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name cn ON mi.info = cn.name
JOIN 
    movie_companies mc ON mc.movie_id = t.id AND mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_info_idx mi_idx ON mi.id = mi_idx.movie_id AND mi_idx.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
JOIN 
    person_info pi ON a.id = pi.person_id
JOIN 
    title ti ON ti.id = (SELECT episode_of_id FROM title WHERE id = t.id)
WHERE 
    t.production_year >= 2000 
    AND a.name LIKE '%Smith%'
ORDER BY 
    t.production_year DESC, a.name;
