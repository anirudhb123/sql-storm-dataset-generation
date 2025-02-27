WITH RECURSIVE MovieHierarchy AS (
    -- Base case: select all titles
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        title t
    WHERE 
        t.season_nr IS NULL
    
    UNION ALL
    
    -- Recursive case: find episodes of series
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        title t
    JOIN 
        title s ON t.episode_of_id = s.id
    JOIN 
        MovieHierarchy mh ON s.id = mh.movie_id
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.actor_count, 0) AS total_actors,
        COALESCE(ac.actor_names, '{}') AS actor_list,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS ranking
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorCounts ac ON mh.movie_id = ac.movie_id
),
FilteredMovies AS (
    -- Filter movies from a specific period and with a certain number of actors
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_actors,
        ms.actor_list
    FROM 
        MovieStats ms
    WHERE 
        ms.production_year BETWEEN 2000 AND 2022
        AND ms.total_actors > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.actor_list,
    COALESCE((SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = fm.movie_id), 0) AS linked_movies
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.total_actors DESC
LIMIT 10;
