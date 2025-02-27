WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000 

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        level + 1
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.movie_id
    JOIN 
        aka_title t ON t.id = ml.movie_id
    WHERE 
        m.level < 3 
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    SUM(CASE WHEN t.production_year < 2010 THEN 1 ELSE 0 END) AS movies_before_2010,
    AVG(p.info::FLOAT) FILTER (WHERE p.info_type_id = 1) AS avg_age_of_actors, 

    CASE 
        WHEN COUNT(DISTINCT c.movie_id) = 0 THEN 'No Movies'
        ELSE 'Active Actor'
    END AS actor_status

FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieCTE m ON c.movie_id = m.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
LEFT JOIN 
    info_type it ON p.info_type_id = it.id
LEFT JOIN 
    aka_title t ON m.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
    AND a.id IS NOT NULL 
GROUP BY 
    a.name
ORDER BY 
    number_of_movies DESC;