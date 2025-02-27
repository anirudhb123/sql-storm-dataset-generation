WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), CastCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cc.cast_count, 0) AS cast_count,
        COALESCE(compc.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastCounts cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        CompanyCounts compc ON mh.movie_id = compc.movie_id
)

SELECT 
    mi.title, 
    mi.production_year,
    mi.cast_count,
    mi.company_count,
    CASE 
        WHEN mi.cast_count = 0 THEN 'No Cast'
        WHEN mi.company_count = 0 THEN 'No Companies'
        ELSE 'Active Movie'
    END AS status,
    (CASE 
        WHEN mi.cast_count > 5 THEN 'Star Studded'
        WHEN mi.cast_count BETWEEN 1 AND 5 THEN 'Moderate Cast'
        ELSE 'No Cast'
    END) AS cast_category
FROM 
    MovieInfo mi
WHERE 
    mi.production_year >= 2000
    AND (mi.cast_count > 0 OR mi.company_count > 0)
ORDER BY 
    mi.production_year DESC, 
    mi.cast_count DESC
LIMIT 10;
