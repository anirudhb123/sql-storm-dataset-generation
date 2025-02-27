WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mt.production_year >= 2000
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        level
    FROM 
        MovieHierarchy
    WHERE 
        title ILIKE '%action%'
),

MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM 
        FilteredMovies m
    JOIN 
        cast_info ca ON m.movie_id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mi.id) AS info_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        FilteredMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)

SELECT 
    f.title AS movie_title,
    f.production_year,
    mc.actor_name,
    mc.actor_rank,
    mi.info_count,
    mi.info_details
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieCast mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON f.movie_id = mi.movie_id
WHERE 
    mc.actor_rank <= 5 OR mc.actor_rank IS NULL
ORDER BY 
    f.production_year DESC, f.title;
