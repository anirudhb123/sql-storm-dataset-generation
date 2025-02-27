SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    co.name AS company_name,
    mt.kind AS company_type,
    COUNT(DISTINCT ca.id) AS total_cast,
    MAX(m.production_year) AS latest_movie_year
FROM 
    title t
JOIN 
    cast_info ca ON t.id = ca.movie_id
JOIN 
    aka_name a ON ca.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 AND mt.kind = 'Production'
GROUP BY 
    t.title, a.name, co.name, mt.kind
HAVING 
    total_cast > 5
ORDER BY 
    latest_movie_year DESC, movie_title ASC;
