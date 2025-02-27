SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT ci.person_role_id) AS role_count
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000 
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 1
ORDER BY 
    role_count DESC, a.name ASC;

This SQL query retrieves a list of actors along with the movies they've appeared in that were released from the year 2000 onwards. It counts the number of distinct roles each actor has in different movies, includes the movie title, production year, and the type of cast roles. Additionally, it consolidates keywords associated with each movie and filters for actors with more than one role in the dataset, finally ordering the results by the number of roles and by actor name.
