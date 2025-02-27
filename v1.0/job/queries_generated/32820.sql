WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year ASC) AS year_rank
    FROM MovieHierarchy mh
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM title m
    LEFT JOIN movie_info mi ON mi.movie_id = m.id
    GROUP BY m.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON cn.id = mc.company_id
    WHERE mc.company_type_id IS NOT NULL
    GROUP BY mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.year_rank,
    COALESCE(mi.info_details, 'No info available') AS movie_info,
    COALESCE(mc.companies, ARRAY['No companies']) AS companies
FROM RankedMovies rm
LEFT JOIN MovieInfo mi ON mi.movie_id = rm.movie_id
LEFT JOIN MovieCompanies mc ON mc.movie_id = rm.movie_id
WHERE rm.year_rank <= 5
ORDER BY rm.production_year DESC, rm.year_rank;
