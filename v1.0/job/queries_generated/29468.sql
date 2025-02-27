SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    string_agg(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.person_id) AS co_starring_count,
    COALESCE(cp.kind, 'Unknown') AS company_type,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS biography,
    SUM(mo.info_id IS NOT NULL) AS info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_info_idx mo ON t.id = mo.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2023
GROUP BY 
    a.name, t.title, t.production_year, cp.kind
ORDER BY 
    t.production_year DESC, a.name;
