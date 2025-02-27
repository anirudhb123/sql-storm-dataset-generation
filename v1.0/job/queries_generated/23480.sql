WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
avg_cast AS (
    SELECT 
        ci.movie_id,
        AVG(COALESCE(ct.kind, 'Unknown Role')) AS avg_role
    FROM 
        cast_info ci
    LEFT JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    a.avg_role,
    CASE 
        WHEN mh.kind_id IN (SELECT kt.id FROM kind_type kt WHERE kt.kind ILIKE '%comedy%') THEN 'Comedy'
        WHEN mh.kind_id IN (SELECT kt.id FROM kind_type kt WHERE kt.kind ILIKE '%drama%') THEN 'Drama'
        ELSE 'Other'
    END AS genre,
    COUNT(DISTINCT cc.company_id) FILTER (WHERE cc.company_type_id IS NOT NULL) AS production_companies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    avg_cast a ON mh.movie_id = a.movie_id
LEFT JOIN 
    keyword_count kc ON mh.movie_id = kc.movie_id
LEFT JOIN 
    movie_companies cc ON mh.movie_id = cc.movie_id
GROUP BY 
    mh.title, mh.production_year, a.avg_role, mh.kind_id
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC, total_cast DESC;
