SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(c.id) AS cast_count,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies_involved
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
    AND a.name ILIKE '%Smith%'
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name ASC;

This query retrieves details about actors named "Smith" and the movies they were involved in, focusing on films produced after 2000. It aggregates keywords related to each movie and counts the number of cast members involved in each film while also listing the companies associated with those movies. The results are grouped by actor name, movie title, and production year, ordered by year and actor's name.
