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
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

RecentMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),

CastInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN rc.role IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rc ON ci.role_id = rc.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ci.total_cast, 0) AS total_cast,
    COALESCE(ci.roles_count, 0) AS roles_count,
    rm.keyword_count,
    CASE 
        WHEN COALESCE(ci.total_cast, 0) > 0 THEN 
            ROUND((CAST(rm.keyword_count AS FLOAT) / ci.total_cast), 2)
        ELSE 
            NULL
    END AS keywords_per_cast
FROM 
    RecentMovies rm
LEFT JOIN 
    CastInfo ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC;
