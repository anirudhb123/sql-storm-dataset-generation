WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        aka_title AS a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE
        mh.level < 5
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rn
    FROM 
        MovieHierarchy AS mh
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role AS cast_role,
        COUNT(ci.person_id) AS num_cast
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cnt.name AS company_name,
        ct.kind AS company_type,
        (SELECT COUNT(*) FROM movie_companies WHERE movie_id = mc.movie_id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cnt ON cnt.id = mc.company_id
    JOIN 
        company_type AS ct ON ct.id = mc.company_type_id
),
FinalResult AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cr.cast_role,
        cr.num_cast,
        ci.company_name,
        ci.company_type,
        ci.company_count
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        CastRoles AS cr ON tm.movie_id = cr.movie_id
    LEFT JOIN 
        CompanyInfo AS ci ON tm.movie_id = ci.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    COALESCE(fr.cast_role, 'Unknown') AS cast_role,
    COALESCE(fr.num_cast, 0) AS num_cast,
    COALESCE(fr.company_name, 'Independent') AS company_name,
    COALESCE(fr.company_type, 'N/A') AS company_type,
    COALESCE(fr.company_count, 0) AS company_count
FROM 
    FinalResult AS fr
WHERE 
    fr.production_year IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title;
