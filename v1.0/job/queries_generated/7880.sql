SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type,
    pi.info AS person_info
FROM 
    movie_info mi
JOIN 
    title t ON mi.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.id = cc.subject_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind = 'Production'
GROUP BY 
    t.title, a.name, c.kind, pi.info
ORDER BY 
    t.production_year DESC, a.name;
