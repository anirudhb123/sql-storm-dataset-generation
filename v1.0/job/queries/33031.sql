WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id, 
        title, 
        production_year, 
        episode_of_id, 
        0 AS level,
        title AS full_path
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL

    UNION ALL

    SELECT 
        a.id AS movie_id,
        a.title, 
        a.production_year,
        a.episode_of_id,
        mh.level + 1,
        mh.full_path || ' -> ' || a.title
    FROM 
        aka_title a
    JOIN 
        MovieHierarchy mh ON a.episode_of_id = mh.movie_id
),
AggregateCast AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieStats AS (
    SELECT 
        m.title, 
        m.production_year,
        mh.level,
        ac.actor_count,
        ac.actor_names,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        aka_title m
    LEFT JOIN 
        MovieHierarchy mh ON m.id = mh.movie_id
    LEFT JOIN 
        AggregateCast ac ON m.id = ac.movie_id
)
SELECT 
    ms.era, 
    COUNT(*) AS total_movies,
    AVG(ms.actor_count) AS average_actor_count,
    MIN(ms.production_year) AS oldest_movie,
    MAX(ms.production_year) AS newest_movie,
    STRING_AGG(ms.actor_names, '; ') AS all_actors
FROM 
    MovieStats ms
WHERE 
    ms.level = 0
GROUP BY 
    ms.era
ORDER BY 
    MS.era;
