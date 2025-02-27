SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT pc.person_id) AS total_people_in_cast
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    t.production_year > 2000 
    AND ct.kind = 'Production'
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, a.name;
