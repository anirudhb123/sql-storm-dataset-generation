SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    cp.kind AS company_type,
    m.info AS movie_info,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type cp ON mc.company_type_id = cp.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.nr_order, cp.kind, m.info
ORDER BY 
    t.production_year DESC, a.name ASC, c.nr_order;
