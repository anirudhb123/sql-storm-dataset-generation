
SELECT 
    t.title,
    a.name AS actor_name,
    ky.kind AS role_type,
    t.production_year,
    k.keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type ky ON t.kind_id = ky.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title,
    a.name,
    ky.kind,
    t.production_year,
    k.keyword
ORDER BY 
    t.production_year DESC, 
    a.name;
