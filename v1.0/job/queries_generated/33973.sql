WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ca.name AS actor_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name ca ON c.person_id = ca.person_id

    UNION ALL

    SELECT 
        c.person_id,
        c.movie_id,
        ca.name AS actor_name,
        ah.depth + 1 AS depth
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id 
    JOIN 
        aka_name ca ON c.person_id = ca.person_id
    WHERE 
        ah.depth < 3
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_actors,
        COUNT(DISTINCT mkc.keyword_id) AS total_keywords,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keyword_list,
        MAX(m.production_year) AS latest_production_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mkc ON m.id = mkc.movie_id
    LEFT JOIN 
        keyword mk ON mk.id = mkc.keyword_id
    GROUP BY 
        m.id, m.title
),
FilteredMovies AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.total_actors,
        ms.total_keywords,
        ms.keyword_list,
        ms.latest_production_year
    FROM 
        MovieStats ms
    WHERE 
        ms.total_actors > 5
        AND ms.latest_production_year > 2000
)
SELECT 
    fm.movie_title,
    fm.total_actors,
    fm.total_keywords,
    fm.keyword_list,
    ah.actor_name,
    ah.depth
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorHierarchy ah ON fm.movie_id = ah.movie_id
ORDER BY 
    fm.total_actors DESC,
    ah.depth,
    fm.movie_title;
