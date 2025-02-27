SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT m.id) AS number_of_movies,
    group_concat(DISTINCT k.keyword) AS keywords,
    MIN(mi.info) AS earliest_release_info,
    MAX(mi.note) AS latest_release_note
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON at.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.id, a.name
HAVING 
    number_of_movies > 5
ORDER BY 
    t.production_year DESC, number_of_movies DESC;
