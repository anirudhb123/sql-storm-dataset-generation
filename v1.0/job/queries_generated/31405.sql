WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
), CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS total_companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
), FinalReport AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        COALESCE(cs.total_companies, 0) AS total_companies,
        CASE 
            WHEN ms.rank_within_year <= 10 THEN 'Top 10'
            WHEN ms.total_cast > 20 THEN 'High Cast'
            ELSE 'Normal'
        END AS movie_category
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyStats cs ON ms.movie_id = cs.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.total_companies,
    fr.movie_category
FROM 
    FinalReport fr
WHERE 
    fr.movie_category = 'Top 10'
ORDER BY 
    fr.production_year DESC, fr.total_cast DESC;

