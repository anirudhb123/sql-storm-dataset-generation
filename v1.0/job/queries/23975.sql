WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id, 
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    WHERE 
        mh.level < 5  
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note NOT LIKE '%cameo%'
    GROUP BY 
        ci.movie_id, rt.role
),
MovieAverages AS (
    SELECT 
        movie_id,
        AVG(role_count) AS average_roles
    FROM 
        CastRoleCounts
    GROUP BY 
        movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        coalesce(ma.average_roles, 0) AS avg_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieAverages ma ON mh.movie_id = ma.movie_id
    WHERE 
        mh.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'A%' 
        )
    AND
        (mh.production_year BETWEEN 2000 AND 2023 OR mh.title LIKE '%Action%') 
)

SELECT 
    fm.title,
    fm.production_year,
    fm.avg_roles,
    COALESCE(NULLIF(fm.avg_roles, 0), (SELECT AVG(avg_roles) FROM FilteredMovies) ) AS fallback_w_avg_roles
FROM 
    FilteredMovies fm
WHERE 
    fm.avg_roles > 1
ORDER BY 
    fm.avg_roles DESC
FETCH FIRST 10 ROWS ONLY;