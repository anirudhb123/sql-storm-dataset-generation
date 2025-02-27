WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title) AS title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
    WHERE 
        h.level < 3
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT(a.name, ' as ', r.role), ', ') AS cast_list,
        COUNT(*) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.movie_info,
        cd.cast_list,
        cd.total_cast,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC, cd.total_cast DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
)
SELECT 
    r.*
FROM 
    RankedMovies r
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year, r.rank;
