WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year,
        ARRAY[m.title] AS title_path,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year,
        mh.title_path || m.title, 
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mh ON mh.id = ml.linked_movie_id
    WHERE 
        mh.level < 5  -- limit depth for efficiency
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS movie_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS movie_count
    FROM 
        MovieHierarchy mh
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.movie_rank,
        rm.movie_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = rm.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id 
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.movie_rank, rm.movie_count
),
MoviesFiltered AS (
    SELECT 
        mwc.movie_id,
        mwc.movie_title,
        mwc.production_year,
        mwc.movie_rank,
        mwc.movie_count,
        mwc.cast_names
    FROM 
        MoviesWithCast mwc
    WHERE 
        mwc.movie_count > 1 AND -- only movies with more than 1 linked movie
        mwc.production_year > 2000  -- only recent productions
)
SELECT 
    mf.movie_id,
    mf.movie_title,
    mf.production_year,
    mf.movie_rank,
    mf.cast_names
FROM 
    MoviesFiltered mf
ORDER BY 
    mf.production_year DESC, 
    mf.movie_rank
LIMIT 10;
