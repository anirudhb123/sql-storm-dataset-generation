WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mt.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year
    FROM MovieHierarchy mh
    WHERE mh.level <= 3
),
CastInfoWithRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    WHERE ci.nr_order IS NOT NULL
    GROUP BY ci.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
MoviesWithCompanies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        mc.company_name,
        mc.company_type,
        RANK() OVER (PARTITION BY fm.movie_id ORDER BY mc.total_companies DESC) AS company_rank
    FROM FilteredMovies fm
    LEFT JOIN MovieCompanies mc ON fm.movie_id = mc.movie_id
)
SELECT 
    mv.title,
    mv.production_year,
    COALESCE(ci.movie_count, 0) AS total_cast_movies,
    COALESCE(ci.roles, 'N/A') AS cast_roles,
    mv.company_name,
    mv.company_type,
    mv.company_rank
FROM MoviesWithCompanies mv
LEFT JOIN CastInfoWithRoles ci ON mv.movie_id = ci.person_id
WHERE mv.production_year IS NOT NULL
  AND mv.company_rank = 1
  AND (mv.company_name IS NOT NULL OR mv.company_type IS NOT NULL)
ORDER BY mv.production_year DESC, mv.title, mv.company_name;
