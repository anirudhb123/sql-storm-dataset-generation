SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    r.role AS actor_role,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
    co.name AS company_name,
    ci.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    company_type ci ON mc.company_type_id = ci.id
WHERE 
    a.name LIKE '%C%'
    AND m.production_year >= 2000
GROUP BY 
    a.id, m.id, r.id, co.id, ci.id
ORDER BY 
    a.name, m.production_year DESC;

This query achieves the following:

1. It selects the names of actors, movie titles, production years, actor roles, relevant keywords, company names, and company types.
2. It joins multiple tables together to gather comprehensive information about actors and the movies they participated in, along with related keywords and production companies.
3. It filters for actor names that contain the letter 'C' and movies released in or after the year 2000.
4. It groups results by actor and movie details to aggregate keywords into a comma-separated list.
5. The final result is ordered first by the actor's name and then by the movie's production year in descending order.
