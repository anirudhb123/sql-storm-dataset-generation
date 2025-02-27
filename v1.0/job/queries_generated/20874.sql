WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE 
            WHEN mi.info_type_id IS NOT NULL THEN LENGTH(mi.info) 
            ELSE 0 
        END) AS avg_info_length,
        MAX(mh.depth) AS max_depth
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.avg_info_length,
        COALESCE(ci.company_count, 0) AS company_count,
        COALESCE(ci.company_names, 'None') AS company_names,
        ms.max_depth,
        CASE 
            WHEN ms.production_year < 2000 THEN 'Classic'
            WHEN ms.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyInfo ci ON ms.movie_id = ci.movie_id
)
SELECT 
    *,
    CASE 
        WHEN cast_count > 0 AND company_count > 0 THEN 'Featured'
        WHEN cast_count > 5 Then 'Large Cast'
        WHEN company_count = 0 THEN 'Independent'
        ELSE 'Limited Info'
    END AS classification,
    RANK() OVER (PARTITION BY era ORDER BY avg_info_length DESC) AS rank_info_length
FROM 
    FinalResults
WHERE 
    title NOT LIKE '%unreleased%'
    AND era = 'Modern'
ORDER BY 
    avg_info_length DESC
LIMIT 50;
