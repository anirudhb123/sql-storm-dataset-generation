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
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
), CompanyAggregates AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.level,
    rc.total_companies,
    rc.company_names,
    CASE 
        WHEN rc.total_companies > 5 THEN 'High Production'
        WHEN rc.total_companies > 0 THEN 'Medium Production'
        ELSE 'No Companies'
    END AS company_category,
    (SELECT COUNT(*)
     FROM cast_info ci
     WHERE ci.movie_id = rm.movie_id
     AND ci.note IS NOT NULL) AS cast_count,
    (SELECT AVG(LENGTH(mi.info))
     FROM movie_info mi
     WHERE mi.movie_id = rm.movie_id) AS avg_info_length
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyAggregates rc ON rm.movie_id = rc.movie_id
WHERE 
    rm.production_year >= 2000
    AND (rm.level = 1 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.rank_within_year
LIMIT 100;
