WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::text AS parent_movie_title -- Serves as a placeholder for parent movie title
    FROM title t
    WHERE t.season_nr IS NULL -- Starting with top-level movies (not episodes)
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_movie_title
    FROM title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.linked_movie_id -- Recursive join to find linked movies
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_role_id,
        COUNT(*) AS role_count
    FROM cast_info ci
    GROUP BY 
        ci.movie_id, 
        ci.person_role_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(cr.role_count), 0) AS total_roles
    FROM MovieHierarchy mh
    LEFT JOIN CastRoles cr ON mh.movie_id = cr.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
MovieYears AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        SUM(total_roles) AS total_cast_roles
    FROM FilteredMovies
    GROUP BY production_year
)
SELECT 
    my.production_year,
    my.movie_count,
    my.total_cast_roles,
    CASE 
        WHEN my.movie_count = 0 THEN NULL
        ELSE my.total_cast_roles::FLOAT / my.movie_count 
    END AS avg_roles_per_movie,
    (SELECT STRING_AGG(DISTINCT t.title, ', ') 
     FROM title t 
     WHERE t.production_year = my.production_year) AS titles
FROM MovieYears my
ORDER BY my.production_year DESC;

