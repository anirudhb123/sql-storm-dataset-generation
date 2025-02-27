
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    p.info AS actor_bio,
    k.keyword AS movie_keyword,
    COUNT(t.id) AS total_movies,
    STRING_AGG(DISTINCT c.kind, ',') AS company_types
FROM 
    aka_name AS a
JOIN 
    cast_info AS ci ON a.person_id = ci.person_id
JOIN 
    title AS t ON ci.movie_id = t.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id
JOIN 
    person_info AS p ON a.person_id = p.person_id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type AS c ON mc.company_type_id = c.id
WHERE 
    t.production_year > 2000 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, t.production_year, p.info, k.keyword
HAVING 
    COUNT(t.id) > 1
ORDER BY 
    total_movies DESC, a.name ASC;
