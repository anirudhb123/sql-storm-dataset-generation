SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    cn.name AS company_name,
    cc.role AS character_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id AND ci.person_id = cc.subject_id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind, cn.name, cc.role
ORDER BY 
    t.production_year DESC, a.name;
