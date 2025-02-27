WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL -- Top-level movies (not episodes)

    UNION ALL

    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        mh.level + 1
    FROM 
        aka_title AS a
    JOIN 
        MovieHierarchy AS mh ON a.episode_of_id = mh.movie_id
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(MAX(mk.keyword), 'No Keywords') AS keywords,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS fact_count
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.keywords,
        c.role,
        c.role_count,
        ROW_NUMBER() OVER (PARTITION BY c.role ORDER BY role_count DESC) AS rank
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        CastRoleCounts AS c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        MovieInfo AS mi ON mh.movie_id = mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.role,
    rm.role_count,
    CASE 
        WHEN rm.role_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_presence,
    mh.level
FROM 
    RankedMovies AS rm
JOIN 
    MovieHierarchy AS mh ON rm.movie_id = mh.movie_id
WHERE 
    rm.rank <= 3
ORDER BY 
    mh.level, rm.role_count DESC;

