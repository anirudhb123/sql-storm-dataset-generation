SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    mt.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    i.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year > 2000
    AND mt.kind = 'Distributor'
GROUP BY 
    a.name, t.title, c.nr_order, mt.kind, i.info
ORDER BY 
    t.production_year DESC, c.nr_order ASC;
