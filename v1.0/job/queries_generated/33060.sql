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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn_in_level,
        COUNT(*) OVER () AS total_movies
    FROM 
        MovieHierarchy mh
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.level,
        rm.rn_in_level,
        rm.total_movies
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn_in_level <= 10
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.note,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MoviesWithCast AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.level,
        STRING_AGG(DISTINCT CONCAT_WS(' - ', ci.note, rc.role), '; ') AS cast_roles
    FROM 
        TopMovies tm
    LEFT JOIN 
        CastInfoWithRoles ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        role_type rc ON ci.role_id = rc.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.level
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.level,
    mwc.cast_roles,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    movie_info mi ON mwc.movie_id = mi.movie_id
WHERE 
    mwc.production_year > 2000
ORDER BY 
    mwc.level, mwc.production_year DESC;
