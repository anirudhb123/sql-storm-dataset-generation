SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT pc.info) AS person_info_count,
    COUNT(DISTINCT m.id) AS movie_company_count
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
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info_idx mii ON t.id = mii.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    COUNT(DISTINCT mk.keyword_id) DESC, a.name;
