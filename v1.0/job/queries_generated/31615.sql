WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

ranked_cast AS (
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(rc.actor_name, 'Unknown') AS main_actor,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.production_year < 2010 THEN 'Classic' 
        ELSE 'Modern' 
    END AS movie_type,
    mh.level
FROM movie_hierarchy mh
LEFT JOIN ranked_cast rc ON mh.movie_id = rc.movie_id AND rc.actor_rank = 1
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 2
ORDER BY 
    mh.production_year DESC, 
    mh.title;

