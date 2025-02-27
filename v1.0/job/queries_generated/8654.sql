SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    m.info_type_id = 1 AND 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
