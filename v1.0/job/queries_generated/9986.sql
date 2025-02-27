SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    ci.nr_order AS role_order, 
    ct.kind AS comp_cast_type, 
    c.name AS company_name, 
    mt.kind AS movie_type, 
    mi.info AS movie_info,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    title t2 ON t.movie_id = t2.id 
JOIN 
    kind_type mt ON t2.kind_id = mt.id 
LEFT JOIN 
    movie_keyword mk ON t2.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info mi ON t2.id = mi.movie_id 
WHERE 
    t.production_year > 2000 
    AND a.name IS NOT NULL 
    AND ci.nr_order IS NOT NULL 
GROUP BY 
    a.name, t.title, ci.nr_order, ct.kind, c.name, mt.kind, mi.info
ORDER BY 
    t.production_year DESC, a.name;
