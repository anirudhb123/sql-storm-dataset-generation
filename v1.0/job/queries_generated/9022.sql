SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_role,
    y.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    info_type it ON cc.subject_id = it.id
JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = it.id
JOIN 
    aka_title at ON t.id = at.movie_id
LEFT JOIN 
    kind_type kt ON t.kind_id = kt.id
LEFT JOIN 
    comp_cast_type cct ON mc.company_type_id = cct.id
WHERE 
    a.name LIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2023
    AND it.info ILIKE '%award%'
GROUP BY 
    a.name, t.title, c.kind, y.production_year
ORDER BY 
    y.production_year DESC, actor_name ASC;
