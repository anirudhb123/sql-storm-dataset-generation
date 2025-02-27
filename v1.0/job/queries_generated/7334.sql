SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    mc.note AS company_note, 
    mi.info AS movie_info, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND cn.country_code = 'USA' 
GROUP BY 
    a.name, t.title, c.kind, mc.note, mi.info 
ORDER BY 
    t.production_year DESC, a.name ASC;
