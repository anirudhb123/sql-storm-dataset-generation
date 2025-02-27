WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title et
        JOIN MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.production_year >= 2000
),

CastWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role AS person_role,
        COUNT(ci.id) OVER (PARTITION BY ci.movie_id) AS total_cast_count
    FROM 
        cast_info ci
        JOIN role_type r ON ci.role_id = r.id
),

MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cwr.person_role,
        cwr.total_cast_count,
        (SELECT COUNT(*) 
         FROM movie_info mi 
         WHERE mi.movie_id = tm.movie_id AND mi.info_type_id = 1) AS info_count -- example type id
    FROM 
        TopMovies tm
        LEFT JOIN CastWithRoles cwr ON tm.movie_id = cwr.movie_id
)

SELECT 
    md.title,
    md.production_year,
    COALESCE(md.person_role, 'No Role Assigned') AS role_assigned,
    md.total_cast_count,
    md.info_count,
    CASE 
        WHEN md.info_count > 0 THEN 'Has Info'
        ELSE 'No Info'
    END AS info_status
FROM 
    MovieDetails md
WHERE 
    md.total_cast_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;

