WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
),
cast_summary AS (
    SELECT 
        a.id AS person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN a.name ILIKE '%(voice)%' THEN 1 ELSE 0 END) AS voice_role_ratio
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies AS mc ON ci.movie_id = mc.movie_id
    WHERE 
        a.name IS NOT NULL 
        AND a.name <> ''
    GROUP BY 
        a.id, a.name
),
movie_key_info AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        COUNT(mi.id) AS info_count
    FROM 
        movie_keyword AS mk
    JOIN 
        movie_info AS mi ON mk.movie_id = mi.movie_id
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    cs.name AS actor_name,
    cs.movie_count,
    cs.voice_role_ratio,
    mk.keywords AS movie_keywords,
    mk.info_count AS additional_info_count,
    CASE
        WHEN cs.voice_role_ratio > 0.5 THEN 'Prominent Voice Actor'
        WHEN cs.movie_count > 10 THEN 'Veteran Actor'
        ELSE 'Newcomer'
    END AS actor_type,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cs.movie_count DESC) AS rank_within_year
FROM 
    movie_hierarchy AS mh
JOIN 
    cast_summary AS cs ON cs.movie_count > 0 AND EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id = mh.movie_id AND ci.person_id = cs.person_id
    )
JOIN 
    movie_key_info AS mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = 1
    AND (mh.production_year = 2021 OR mh.production_year = 2022)
ORDER BY 
    mh.production_year, rank_within_year;
