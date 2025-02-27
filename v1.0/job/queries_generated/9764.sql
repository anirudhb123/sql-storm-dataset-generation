SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    k.keyword AS movie_keyword,
    ci.info AS additional_info,
    cn.name AS company_name,
    GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    info_type it ON ci.note = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND cn.country_code IN ('USA', 'UK', 'CAN')
GROUP BY 
    t.title, a.name, c.kind, k.keyword, ci.info, cn.name
ORDER BY 
    t.production_year DESC, a.name;
