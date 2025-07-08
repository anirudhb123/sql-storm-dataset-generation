
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    COUNT(ci.id) AS number_of_roles,
    AVG(CAST(mi.info AS FLOAT)) AS average_rating
FROM 
    aka_title AS t
JOIN 
    complete_cast AS cc ON t.id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_type AS c ON mc.company_type_id = c.id
JOIN 
    movie_info AS mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    average_rating DESC, movie_title ASC;
