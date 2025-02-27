SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    comp.name AS company_name,
    ti.info AS movie_info,
    CASE 
        WHEN m.production_year IS NOT NULL THEN m.production_year 
        ELSE 'Unknown Year' 
    END AS production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
LEFT JOIN 
    aka_title at ON at.movie_id = t.id
WHERE 
    a.name LIKE 'A%'
GROUP BY 
    a.name, t.title, c.kind, comp.name, ti.info, m.production_year
ORDER BY 
    production_year DESC, actor_name;
