SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS companies_involved,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = t.id AND ci.person_role_id IS NOT NULL) AS total_cast,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_available
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
