SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    p.info AS actor_info,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    c.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_info,
    ti.note AS movie_info_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info_idx ti ON t.id = ti.movie_id
GROUP BY 
    a.name, t.title, p.info, c.name, ct.kind, ti.info, ti.note
ORDER BY 
    COUNT(DISTINCT kc.keyword) DESC, t.production_year DESC;
