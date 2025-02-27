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
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
aggregated_cast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ac.actor_names,
        ac.role_count,
        ROW_NUMBER() OVER(PARTITION BY mh.production_year ORDER BY ac.role_count DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        aggregated_cast ac ON mh.movie_id = ac.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.actor_names, 'No actors found') AS actor_names,
    rm.role_count,
    CAST(rm.rank AS INTEGER) AS rank
FROM 
    ranked_movies rm
WHERE 
    rm.role_count > 2
ORDER BY 
    rm.production_year DESC, rm.rank;
