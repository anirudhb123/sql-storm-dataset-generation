SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    COALESCE(ct.kind, 'N/A') AS company_type,
    COUNT(DISTINCT m.id) AS movie_count,
    SUM(LENGTH(m.title) - LENGTH(REPLACE(m.title, ' ', ''))) + 1 AS word_count_in_titles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year >= 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, m.title, k.keyword, p.info, ct.kind
ORDER BY 
    movie_count DESC, actor_name ASC;
