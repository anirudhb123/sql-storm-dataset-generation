
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    COUNT(*) AS total_movies
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword IN ('action', 'drama', 'comedy')
GROUP BY 
    t.title, a.name, p.info, ct.kind, k.keyword
ORDER BY 
    total_movies DESC
LIMIT 10;
