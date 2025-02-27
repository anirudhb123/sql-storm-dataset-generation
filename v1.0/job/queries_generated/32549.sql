WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        cd.cast_count,
        cd.actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.movie_rank <= 5
        AND (cd.cast_count IS NULL OR cd.cast_count > 5)
)
SELECT 
    fm.movie_title,
    fm.production_year,
    COALESCE(fm.cast_count, 0) AS cast_count,
    COALESCE(fm.actor_names, 'Unknown') AS actor_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
