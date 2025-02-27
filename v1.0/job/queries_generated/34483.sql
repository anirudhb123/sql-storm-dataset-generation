WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        mh.level + 1 AS level
    FROM 
        aka_title AS m
    JOIN 
        movie_link AS ml ON m.id = ml.linked_movie_id 
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        an.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    WHERE 
        ci.nr_order IS NOT NULL
),

movies_with_cast AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.keyword,
        COUNT(DISTINCT rc.actor_name) AS actor_count,
        MAX(rc.actor_rank) AS max_actor_rank
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        ranked_cast AS rc ON mh.movie_id = rc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.keyword
)

SELECT 
    mwc.title,
    mwc.production_year,
    mwc.keyword,
    mwc.actor_count,
    CASE 
        WHEN mwc.actor_count > 5 THEN 'High Cast' 
        WHEN mwc.actor_count BETWEEN 3 AND 5 THEN 'Moderate Cast' 
        ELSE 'Low Cast' 
    END AS cast_category
FROM 
    movies_with_cast AS mwc
WHERE 
    mwc.actor_count IS NOT NULL
ORDER BY 
    mwc.production_year DESC,
    mwc.actor_count DESC
LIMIT 50;
