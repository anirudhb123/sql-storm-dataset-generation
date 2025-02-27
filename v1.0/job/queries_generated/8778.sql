SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type,
    k.keyword AS keyword,
    array_agg(DISTINCT k.keyword) AS associated_keywords,
    COUNT(DISTINCT m.id) AS number_of_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, a.name, p.info, c.kind, k.keyword
ORDER BY 
    number_of_movies DESC, t.title ASC
LIMIT 50;
