WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.id
    ORDER BY 
        actor_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    ARRAY_LENGTH(STRING_TO_ARRAY(rm.actor_names, ', '), 1) AS number_of_actors,
    (SELECT STRING_AGG(DISTINCT t.title, ', ') 
     FROM title t 
     JOIN movie_link ml ON t.id = ml.linked_movie_id 
     WHERE ml.movie_id = (SELECT a.id FROM aka_title a WHERE a.title = rm.movie_title LIMIT 1)) AS linked_movies
FROM 
    RankedMovies rm
JOIN 
    movie_info mi ON (SELECT a.id FROM aka_title a WHERE a.title = rm.movie_title LIMIT 1) = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
ORDER BY 
    rm.production_year ASC;
