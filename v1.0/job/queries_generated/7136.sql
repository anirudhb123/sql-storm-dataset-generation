SELECT 
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    p.info AS person_info,
    k.keyword AS movie_keywords,
    GROUP_CONCAT(DISTINCT cc.kind ORDER BY cc.kind) AS company_types
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type cc ON mc.company_type_id = cc.id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.id, t.id, c.role_id, p.info
ORDER BY 
    t.production_year DESC, a.name;
