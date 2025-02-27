
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies,
        COALESCE(mt.keyword_count, 0) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(keyword_id) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) mt ON mh.movie_id = mt.movie_id
),
Actors AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info ca
    GROUP BY 
        ca.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.level,
    rm.title_rank,
    rm.total_movies,
    rm.keyword_count,
    COALESCE(ac.actor_count, 0) AS actor_count,
    CASE 
        WHEN rm.level = 1 THEN 'Main Feature'
        ELSE 'Episode'
    END AS movie_type
FROM 
    RankedMovies rm
LEFT JOIN 
    Actors ac ON rm.movie_id = ac.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.production_year DESC, 
    rm.level, 
    rm.title_rank;
