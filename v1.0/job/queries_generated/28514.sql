SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    c.kind AS company_type,
    pi.info AS person_info,
    cnt AS actor_count
FROM 
    aka_title t
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
GROUP BY 
    t.title, a.name, ct.kind, pi.info
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    actor_count DESC, t.title;

