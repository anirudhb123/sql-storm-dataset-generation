SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT kc.id) AS keyword_count,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    MAX(m.production_year) AS latest_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    aka_title at ON t.id = at.movie_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL 
    AND (k.keyword LIKE '%action%' OR k.keyword LIKE '%drama%')
GROUP BY 
    t.id, a.name
ORDER BY 
    keyword_count DESC, latest_production_year ASC;
