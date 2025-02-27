SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    y.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.id = cc.subject_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    cmp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    title y ON y.id = t.id
WHERE 
    y.production_year >= 2000
GROUP BY 
    t.id, a.id, c.kind, y.production_year
ORDER BY 
    y.production_year DESC, t.title ASC;
