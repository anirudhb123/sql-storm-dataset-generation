SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT c.role_id ORDER BY c.nr_order) AS roles,
    m.name AS company_name,
    ik.info AS keyword_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ik ON mk.keyword_id = ik.id
WHERE 
    t.production_year > 2000
    AND m.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, m.name
HAVING 
    COUNT(DISTINCT a.id) > 1
ORDER BY 
    t.production_year DESC, a.name;
