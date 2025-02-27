SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    COUNT(m.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year >= 2000
GROUP BY 
    a.name, t.title, c.kind, p.info, k.keyword
ORDER BY 
    total_movies DESC, avg_production_year ASC
LIMIT 100;
