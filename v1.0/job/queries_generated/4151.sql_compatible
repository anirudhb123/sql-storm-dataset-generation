
WITH MovieTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopGenres AS (
    SELECT 
        kt.kind AS genre, 
        COUNT(mt.title) AS movie_count
    FROM 
        kind_type kt
    JOIN 
        aka_title at ON kt.id = at.kind_id
    JOIN 
        MovieTitles mt ON at.title = mt.title
    GROUP BY 
        kt.kind
    ORDER BY 
        movie_count DESC
    LIMIT 5
),
ActorInfo AS (
    SELECT 
        an.name AS actor_name, 
        COUNT(DISTINCT c.movie_id) AS movies_played,
        AVG(EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year) AS avg_movie_age
    FROM 
        aka_name an
    JOIN 
        cast_info c ON an.person_id = c.person_id
    JOIN 
        aka_title mt ON c.movie_id = mt.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        an.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
)
SELECT 
    ti.genre, 
    ai.actor_name, 
    ai.movies_played,
    ai.avg_movie_age
FROM 
    TopGenres ti
CROSS JOIN 
    ActorInfo ai
WHERE 
    ai.avg_movie_age IS NOT NULL
ORDER BY 
    ti.movie_count DESC, ai.movies_played DESC;
