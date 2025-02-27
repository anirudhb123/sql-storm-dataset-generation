SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    COUNT(mk.keyword) AS keyword_count,
    COUNT(DISTINCT pc.info) AS unique_personal_info,
    co.name AS company_name,
    ti.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type it ON pi.info_type_id = it.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    title ti ON mi.movie_id = ti.id
WHERE 
    t.production_year >= 2000
    AND a.imdb_index IS NOT NULL
    AND mk.keyword ILIKE '%comedy%'
GROUP BY 
    a.name, t.title, c.kind, co.name, ti.info
ORDER BY 
    keyword_count DESC, actor_name ASC;
