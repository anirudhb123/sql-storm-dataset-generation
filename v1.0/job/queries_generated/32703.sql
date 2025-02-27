WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id = (SELECT MIN(id) FROM aka_title WHERE production_year IS NOT NULL)

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mi.company_count,
        mi.keyword_count,
        mi.rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
    WHERE 
        mh.level <= 3
        AND (mi.company_count > 5 OR mi.keyword_count > 10)
)

SELECT 
    CAST(mf.title AS TEXT) AS movie_title,
    COALESCE(mf.production_year, 'N/A') AS production_year,
    MF.company_count,
    MF.keyword_count,
    CASE 
        WHEN MF.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Available'
    END AS company_status,
    CASE 
        WHEN MF.keyword_count IS NULL OR MF.keyword_count = 0 THEN 'No Keywords'
        ELSE 'Keywords Available'
    END AS keyword_status
FROM 
    FilteredMovies MF
WHERE 
    MF.rank <= 10
ORDER BY 
    MF.production_year DESC, MF.title;

