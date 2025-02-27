SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role,
    c.kind AS comp_cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(m.movie_id) AS number_of_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    info_type it ON mc.note = it.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year > 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind
HAVING 
    COUNT(mk.keyword_id) > 5
ORDER BY 
    number_of_movies DESC;
