SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS role,
    cm.name AS company_name,
    GROUP_CONCAT(k.keyword) AS keywords,
    MIN(mi.info) AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND ak.name IS NOT NULL 
GROUP BY 
    t.title, ak.name, c.kind, cm.name
ORDER BY 
    t.production_year DESC;
