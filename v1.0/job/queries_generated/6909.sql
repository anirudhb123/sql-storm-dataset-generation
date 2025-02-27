SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    mn.name AS production_company,
    mi.info AS movie_info,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name mn ON mc.company_id = mn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword mk ON t.id = mk.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year > 2000 
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%Awards%')
GROUP BY 
    a.name, t.title, c.kind, mn.name, mi.info
ORDER BY 
    keyword_count DESC, a.name;
