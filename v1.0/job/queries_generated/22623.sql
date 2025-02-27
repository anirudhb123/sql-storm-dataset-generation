WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_aggregate AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.role_id IS NOT NULL THEN ci.person_id END) AS credited_cast,
        COUNT(DISTINCT ci.id) FILTER (WHERE ci.note IS NOT NULL) AS notes_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT co.country_code) AS unique_country_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    ca.total_cast,
    ca.credited_cast,
    ca.notes_count,
    ci.companies,
    ci.unique_country_count,
    COALESCE(NULLIF(NULLIF(mh.path, ''), NULL), 'No linked movies') AS path_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_aggregate ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    company_info ci ON mh.movie_id = ci.movie_id
WHERE 
    mh.production_year >= 2000
    AND (mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short')))
    AND (mh.movie_title ILIKE ANY (ARRAY['%adventure%', '%fantasy%', '%sci-fi%']))
ORDER BY 
    mh.production_year DESC,
    mh.level ASC,
    ca.total_cast DESC
LIMIT 100 OFFSET 50;
