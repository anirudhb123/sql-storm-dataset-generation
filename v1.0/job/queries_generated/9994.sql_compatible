
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name ILIKE '%Smith%' 
    AND t.production_year >= 2000 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    a.name, t.title, ct.kind, mi.info
ORDER BY 
    keyword_count DESC, actor_name;
