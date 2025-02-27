SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    pt.info AS plot_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.name AS company_name,
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info = 'Plot'
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    a.name IS NOT NULL
AND 
    m.production_year > 1990
GROUP BY 
    a.name, m.title, m.production_year, pt.info, c.name, ct.kind
ORDER BY 
    m.production_year DESC, a.name ASC;
