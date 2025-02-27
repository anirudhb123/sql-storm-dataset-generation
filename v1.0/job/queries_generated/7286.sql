SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS role_type, 
    c.nr_order AS role_order, 
    p.info AS person_info, 
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
    GROUP_CONCAT(DISTINCT mi.info ORDER BY mi.info) AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.id, a.id, c.id, p.id
ORDER BY 
    t.title, a.name;
