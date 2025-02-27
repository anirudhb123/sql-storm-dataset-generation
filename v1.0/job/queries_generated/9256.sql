SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_kind,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT p.info) AS distinct_info_count
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND c.country_code = 'USA'
GROUP BY 
    t.title, a.name, c.kind, m.info, k.keyword
ORDER BY 
    distinct_info_count DESC, t.title ASC
LIMIT 50;
