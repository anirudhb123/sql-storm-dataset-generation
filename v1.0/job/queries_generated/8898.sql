SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(c.id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
AND 
    a.name IS NOT NULL
AND 
    cn.country_code = 'USA'
GROUP BY 
    t.title, a.name
HAVING 
    COUNT(c.id) > 5
ORDER BY 
    total_cast DESC, movie_title ASC;
