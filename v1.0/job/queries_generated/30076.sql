WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RoleCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MoviesWithRoles AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(rc.role_count, 0) AS role_count,
        mh.depth
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RoleCounts rc ON mh.movie_id = rc.movie_id
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY role_count DESC, title) AS rank
    FROM 
        MoviesWithRoles
)
SELECT 
    rm.title,
    rm.production_year,
    rm.role_count,
    rm.depth,
    CASE 
        WHEN rm.role_count = 0 THEN 'No roles'
        ELSE 'Roles exist'
    END AS role_info
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC,
    rm.role_count DESC;
