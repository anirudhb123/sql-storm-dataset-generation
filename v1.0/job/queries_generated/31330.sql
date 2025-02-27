WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mh.level < 3 -- Limit recursion depth
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_title a ON c.movie_id = a.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        c.person_id
),
FilteredActors AS (
    SELECT 
        na.name,
        ac.movie_count
    FROM 
        ActorMovieCounts ac
    JOIN 
        aka_name na ON ac.person_id = na.person_id
    WHERE 
        ac.movie_count > 3
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    tm.title AS Movie,
    tm.production_year AS Year,
    COALESCE(fa.movie_count, 0) AS Actor_Count,
    tm.actor_count AS Total_Actors,
    (SELECT COUNT(*)
     FROM aka_title at
     WHERE at.production_year = tm.production_year
       AND at.title LIKE '%Drama%') AS Drama_Movies_This_Year
FROM 
    TopMovies tm
LEFT JOIN 
    FilteredActors fa ON fa.movie_count > 0
WHERE 
    tm.actor_count > 5
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC
LIMIT 50;
