WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level 
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 3
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.movie_title) AS title_rank
    FROM 
        MovieHierarchy mh
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        MAX(ct.kind) AS primary_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),

FinalOutput AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        COALESCE(cs.total_companies, 0) AS total_companies,
        COALESCE(cs.primary_company_type, 'Unknown') AS primary_company_type,
        rm.production_year,
        CASE 
            WHEN rm.title_rank = 1 THEN 'Top Ranked'
            ELSE 'Other'
        END AS ranking_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
)

SELECT 
    f.movie_id,
    f.movie_title,
    f.total_companies,
    f.primary_company_type,
    f.production_year,
    f.ranking_category,
    count(c.id) AS cast_count,
    AVG(CASE WHEN CAST(i.info AS BOOLEAN) IS NULL THEN 0 ELSE 1 END) AS cast_info_presence_rate
FROM 
    FinalOutput f
LEFT JOIN 
    complete_cast c ON f.movie_id = c.movie_id
LEFT JOIN 
    movie_info i ON f.movie_id = i.movie_id AND i.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
WHERE 
    (f.production_year IS NOT NULL AND f.production_year BETWEEN 1990 AND 2020)
    AND (f.total_companies > 0 OR f.primary_company_type IS NOT NULL)
GROUP BY 
    f.movie_id, f.movie_title, f.total_companies, f.primary_company_type, f.production_year, f.ranking_category
HAVING 
    (count(c.id) > 2 AND AVG(CASE WHEN CAST(i.info AS BOOLEAN) IS NULL THEN 0 ELSE 1 END) > 0.5)
ORDER BY 
    f.production_year DESC, f.movie_title;
