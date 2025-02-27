WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
,
DistinctKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
,
CompanyCounts AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        aka_title m ON mc.movie_id = m.id
    GROUP BY
        m.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    d.keywords,
    cc.company_count,
    COALESCE(CASE 
        WHEN mh.production_year < 2010 THEN 'Older Movie'
        ELSE 'Newer Movie'
    END, 'Unknown') AS movie_age_category,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS row_num
FROM
    MovieHierarchy mh
LEFT JOIN
    DistinctKeywords d ON mh.movie_id = d.movie_id
LEFT JOIN
    CompanyCounts cc ON mh.movie_id = cc.movie_id
WHERE
    cc.company_count IS NULL OR cc.company_count > 2
ORDER BY
    mh.production_year DESC, 
    mh.level ASC;
