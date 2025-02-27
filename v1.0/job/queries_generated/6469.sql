SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_kind,
    cc.note AS cast_note,
    COUNT(mk.keyword_id) AS keyword_count,
    STRING_AGG(kw.keyword, ', ') AS keywords,
    COALESCE(MAX(CASE WHEN ti.info_type_id = 1 THEN mi.info END), 'N/A') AS movie_summary
FROM 
    aka_name a
JOIN 
    cast_info cc ON a.person_id = cc.person_id
JOIN 
    title t ON cc.movie_id = t.id
JOIN 
    comp_cast_type cct ON cc.person_role_id = cct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, cc.note
HAVING 
    COUNT(mk.keyword_id) > 2
ORDER BY 
    actor_name, movie_title;
