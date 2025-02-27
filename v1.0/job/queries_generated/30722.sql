WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title m

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT ci.person_id AS cast_count,
        STRING_AGG(DISTINCT CONCAT(an.name, ' (', rt.role, ')'), ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(cd.cast_count, 0) AS total_cast,
        COALESCE(cd.cast_names, 'No Cast') AS cast_details,
        COALESCE(array_agg(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), '{}') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        CastDetails cd ON m.id = cd.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, cd.cast_count, cd.cast_names
),

RankedMovies AS (
    SELECT 
        mi.movie_id,
        mi.movie_title,
        mi.production_year,
        mi.total_cast,
        mi.cast_details,
        RANK() OVER (PARTITION BY mi.production_year ORDER BY mi.total_cast DESC) AS rank_within_year
    FROM 
        MovieInfo mi
    WHERE 
        mi.production_year IS NOT NULL
)

SELECT 
    mh.movie_id,
    mh.title AS movie_hierarchy_title,
    mh.production_year,
    rm.rank_within_year,
    rm.cast_details,
    COUNT(DISTINCT ml.linked_movie_id) AS related_movies_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON mh.movie_id = rm.movie_id
LEFT JOIN 
    movie_link ml ON mh.movie_id = ml.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, rm.rank_within_year, rm.cast_details
ORDER BY 
    mh.production_year DESC, rm.rank_within_year;
