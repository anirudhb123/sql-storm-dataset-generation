WITH RECURSIVE movie_hierarchy AS (
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
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),

movie_info_detail AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT it.info, '; ') AS info
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON mi.movie_id = mk.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    rc.actor_name,
    rc.actor_rank,
    rc.total_actors,
    mid.keywords,
    mid.info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    ranked_cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    movie_info_detail mid ON mh.movie_id = mid.movie_id
WHERE 
    mh.level = 2 
    AND mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    rc.actor_rank
LIMIT 100;
