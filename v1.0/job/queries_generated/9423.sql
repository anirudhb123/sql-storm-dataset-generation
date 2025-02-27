SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    r.role AS role_type,
    p.info AS person_info,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    COUNT(m.movie_id) AS total_movies,
    MIN(m.production_year) AS earliest_movie_year,
    MAX(m.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.nr_order, r.role, p.info, co.name, k.keyword
ORDER BY 
    total_movies DESC, earliest_movie_year ASC;
