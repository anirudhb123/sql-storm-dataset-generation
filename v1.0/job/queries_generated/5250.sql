SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    r.role AS role_name, 
    m.production_year AS year_produced, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000 
    AND cn.country_code = 'USA'
GROUP BY 
    a.id, t.id, ci.nr_order, r.id, m.production_year
ORDER BY 
    m.production_year DESC, actor_name;
