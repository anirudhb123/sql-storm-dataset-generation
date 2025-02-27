
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT c.id) AS total_cast_members
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    t.production_year DESC, actor_name ASC;
