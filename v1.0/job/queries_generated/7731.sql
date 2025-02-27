SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    kt.keyword AS movie_keyword,
    ci.kind AS company_type,
    ti.info AS movie_info,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.nr_order, kt.keyword, ci.kind, ti.info
ORDER BY 
    keyword_count DESC, actor_name, movie_title;
