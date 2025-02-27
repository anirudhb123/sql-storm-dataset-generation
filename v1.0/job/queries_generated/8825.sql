SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name) AS company_names,
    AVG(pi.info) AS average_info_score
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    person_info pi ON a.person_id = pi.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
AND 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating') 
GROUP BY 
    a.name, t.title, t.production_year 
ORDER BY 
    t.production_year DESC, a.name ASC;
