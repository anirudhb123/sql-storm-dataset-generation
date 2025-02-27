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
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title ep
    JOIN 
        MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(pi.info::numeric) AS average_rating
    FROM
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id AND it.info = 'rating'
    LEFT JOIN 
        person_info pi ON ci.person_id = pi.person_id
    WHERE 
        mh.level = 1
    GROUP BY 
        mh.title, mh.production_year
),
RankedMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.average_rating,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.average_rating DESC) AS ranking
    FROM 
        MovieStats ms
)
SELECT 
    rm.production_year,
    rm.title,
    rm.cast_count,
    rm.average_rating,
    COALESCE(NULLIF(rm.ranking, 1), 'N/A') AS ranking_position,
    (SELECT STRING_AGG(name, ', ') 
     FROM aka_name an 
     JOIN cast_info ci ON an.person_id = ci.person_id 
     WHERE ci.movie_id = rm.movie_id) AS cast_names
FROM 
    RankedMovies rm
WHERE 
    rm.average_rating IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.average_rating DESC;
This SQL query attempts to benchmark movie performance by assembling cast and average ratings data. It constructs a recursive common table expression (CTE) to navigate possible movie hierarchies, aggregating cast counts and average ratings, and then ranks the movies to provide a detailed view of movie statistics per production year. It incorporates outer joins and complex predicates, providing added utility by listing cast names as a concatenated string.
