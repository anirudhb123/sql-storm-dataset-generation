WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5
), 

actor_summary AS (
    SELECT
        ai.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT ai.movie_id) AS movie_count,
        AVG(CASE WHEN it.info_type_id = 1 THEN CAST(it.info AS INTEGER) ELSE NULL END) AS average_age
    FROM 
        cast_info ai
    LEFT JOIN 
        aka_name ak ON ai.person_id = ak.person_id
    LEFT JOIN 
        person_info it ON ai.person_id = it.person_id AND it.info_type_id = 1
    GROUP BY
        ai.person_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
)

SELECT 
    mh.title,
    mh.production_year,
    asu.actor_names,
    ksu.keyword,
    ksu.keyword_count,
    CASE 
        WHEN mh.production_year IS NOT NULL THEN mh.production_year 
        ELSE 'Unknown' 
    END AS processed_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_summary asu ON asu.movie_count > 2
LEFT JOIN 
    keyword_summary ksu ON mh.movie_id = ksu.movie_id
WHERE 
    (mh.production_year = 2021 OR mh.title LIKE '%Saga%')
    AND (ksu.keyword_count IS NULL OR ksu.keyword_count >= 3)
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC
LIMIT 50;
