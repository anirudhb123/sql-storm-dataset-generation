SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    pt.info AS person_info,
    COUNT(ct.id) AS total_cast_members,
    MIN(t.production_year) AS earliest_movie_year,
    MAX(t.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pt ON a.person_id = pt.person_id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    AND c.country_code IN ('USA', 'UK')
    AND pt.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
GROUP BY 
    a.name, t.title, c.name, k.keyword, pt.info
ORDER BY 
    total_cast_members DESC, earliest_movie_year ASC;
