WITH ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        titles,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorRoles
    WHERE 
        movie_count > 1
),
HighRatedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names,
        AVG(CASE 
            WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS FLOAT) 
            ELSE NULL 
        END) AS average_rating
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = cc.subject_id
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.title, m.production_year
    HAVING 
        COUNT(DISTINCT ak.name) > 3
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    ta.titles,
    hmv.title AS high_rated_movie,
    hmv.production_year,
    hmv.average_rating
FROM 
    TopActors ta
JOIN 
    HighRatedMovies hmv ON ta.titles ILIKE '%' || hmv.title || '%'
WHERE 
    hmv.average_rating IS NOT NULL
ORDER BY 
    ta.rank, hmv.average_rating DESC
LIMIT 10;