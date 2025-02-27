
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id AS role_id,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mi.info_type_id) AS info_count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND ct.kind ILIKE 'production%'
GROUP BY 
    t.title, a.name, c.role_id, ct.kind
ORDER BY 
    COUNT(DISTINCT mi.info_type_id) DESC, t.title ASC
LIMIT 100;
