WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year < 2020
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        RANK() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC, mh.title) AS rank_within_kind
    FROM 
        movie_hierarchy mh
),
actor_info AS (
    SELECT 
        ak.person_id,
        ak.name,
        ci.movie_id,
        ci.nr_order AS role_order,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ci.nr_order) AS role_number
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ci.note IS NULL
),
summary AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        rm.rank_within_kind,
        COUNT(DISTINCT ai.person_id) AS actor_count,
        STRING_AGG(DISTINCT ai.name, ', ') AS actors
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON rm.movie_id = ai.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.rank_within_kind
)
SELECT 
    s.movie_title,
    s.production_year,
    s.rank_within_kind,
    s.actor_count,
    CASE 
        WHEN s.actor_count > 0 THEN s.actors 
        ELSE 'No actors' 
    END AS actor_list
FROM 
    summary s
WHERE 
    s.rank_within_kind = 1
ORDER BY 
    s.production_year DESC, s.movie_title;

