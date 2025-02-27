SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT pc.person_id) AS total_persons_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
GROUP BY 
    a.name, t.title, c.kind
HAVING 
    COUNT(DISTINCT pi.info_type_id) > 1
ORDER BY 
    actor_name ASC, movie_title DESC;
