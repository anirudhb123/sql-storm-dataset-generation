WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Start with movies from the year 2000 onwards
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id -- Recursive link to get related movies
),
AggregatedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FilteredMovies AS (
    SELECT 
        am.movie_id,
        am.title,
        am.production_year,
        am.actor_count,
        am.actor_names,
        ROW_NUMBER() OVER (PARTITION BY am.production_year ORDER BY am.actor_count DESC) AS rank
    FROM 
        AggregatedMovies am
    WHERE 
        am.actor_count >= 5 -- Only consider movies with 5 or more actors
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.actor_names
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10 -- Top 10 movies by actor count per year
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;

