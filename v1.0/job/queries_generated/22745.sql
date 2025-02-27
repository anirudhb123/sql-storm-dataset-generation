WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        0 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title, 
        at.production_year, 
        mh.level + 1 AS level,
        mh.path || at.title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.*, 
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level, mh.title) AS rank_within_year
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.level < 3
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.level, 
    rm.rank_within_year, 
    mci.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    (rm.production_year IS NOT NULL OR rm.rank_within_year IS NULL) -- Handling NULL logic
    AND (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) > 5 -- Correlated Subquery
ORDER BY 
    rm.production_year DESC, 
    rm.level, 
    rm.rank_within_year
FETCH FIRST 10 ROWS ONLY;
