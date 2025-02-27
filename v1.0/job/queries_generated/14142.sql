SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    c.kind AS company_type,
    pi.info AS person_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
GROUP BY 
    t.title, a.name, c.kind, pi.info
ORDER BY 
    t.title, a.name;
