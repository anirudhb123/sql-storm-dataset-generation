
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT mi.info) AS info_count,
    STRING_AGG(DISTINCT mi.info, ', ') AS additional_info,
    ARRAY_AGG(DISTINCT t.production_year) AS production_years
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND LOWER(a.name) LIKE '%smith%' 
    AND ci.nr_order < 5 
GROUP BY 
    t.title, a.name, r.role, c.name, k.keyword, t.production_year
ORDER BY 
    info_count DESC, 
    t.title;
