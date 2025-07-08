
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT c.person_id) AS actor_count,
    LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actor_names,
    ct.kind AS company_type,
    cct.kind AS cast_type,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    comp_cast_type cct ON c.person_role_id = cct.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    t.title, ct.kind, cct.kind, ti.info
ORDER BY 
    movie_title;
