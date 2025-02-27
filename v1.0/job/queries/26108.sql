SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    c.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    COUNT(DISTINCT m.id) AS total_movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
    AND t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%Action%'
GROUP BY 
    t.title, a.name, p.info, k.keyword, c.name, ct.kind
ORDER BY 
    total_movies DESC, movie_title ASC;
