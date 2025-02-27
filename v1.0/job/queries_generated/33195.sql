WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
),
casting_data AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
final_results AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.actor_name,
        cd.actor_rank,
        kc.keyword_count,
        COALESCE(cd.nr_order, 0) AS order_number
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        casting_data cd ON mh.movie_id = cd.movie_title
    LEFT JOIN 
        keyword_counts kc ON mh.movie_id = kc.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.actor_rank,
    fr.keyword_count,
    CASE 
        WHEN fr.order_number IS NULL THEN 'No casting information' 
        ELSE 'Casting order: ' || fr.order_number 
    END AS casting_info
FROM 
    final_results fr
WHERE 
    fr.production_year BETWEEN 2000 AND 2020
    AND (fr.keyword_count IS NULL OR fr.keyword_count > 2)
ORDER BY 
    fr.production_year DESC, 
    fr.actor_rank;
