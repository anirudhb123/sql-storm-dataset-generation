SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    ct.kind AS character_type,
    cn.name AS company_name,
    m.info AS movie_info,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    comp_cast_type cct ON c.person_role_id = cct.id
WHERE 
    t.production_year >= 2000 
    AND c.nr_order IS NOT NULL
GROUP BY 
    a.name, t.title, c.nr_order, ct.kind, cn.name, m.info
ORDER BY 
    t.production_year DESC, a.name;
