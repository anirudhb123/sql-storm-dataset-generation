WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        linked_movie.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link linked_movie ON mh.movie_id = linked_movie.movie_id
    JOIN 
        aka_title m ON linked_movie.linked_movie_id = m.id
    WHERE 
        mh.level < 5  -- Limiting depth of recursion
),

TopMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Filter for movies only
    GROUP BY 
        m.id
    ORDER BY 
        cast_count DESC
    LIMIT 10
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS actors,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END), 0) AS total_budget
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

FinalResult AS (
    SELECT 
        td.movie_id,
        td.title,
        td.production_year,
        td.actors,
        td.total_budget,
        ROW_NUMBER() OVER (PARTITION BY td.production_year ORDER BY td.total_budget DESC) AS budget_rank
    FROM 
        MovieDetails td
    WHERE 
        td.total_budget > 0
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actors,
    fr.total_budget,
    fr.budget_rank
FROM 
    FinalResult fr
WHERE 
    fr.budget_rank <= 3  -- Top 3 movies by budget for each year
ORDER BY 
    fr.production_year, 
    fr.budget_rank;

