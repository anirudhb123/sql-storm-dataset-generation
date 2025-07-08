
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    ci.note AS cast_note,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info = 'Plot'
    )
WHERE 
    t.production_year >= 2000 
    AND (a.name LIKE '%Smith%' OR a.name LIKE '%Jones%')
GROUP BY 
    t.title, a.name, r.role, ci.note, mi.info
HAVING 
    COUNT(DISTINCT kw.keyword) > 2
ORDER BY 
    movie_title, actor_name;
