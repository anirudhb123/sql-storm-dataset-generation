WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        1 AS depth
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.total_actors,
        ca.actor_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
    WHERE 
        mh.depth <= 3 AND
        mh.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
),
ranked_movies AS (
    SELECT 
        fm.*,
        RANK() OVER (PARTITION BY fm.production_year ORDER BY fm.total_actors DESC) AS rank_within_year
    FROM 
        filtered_movies fm
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_actors,
    rm.actor_names,
    COALESCE(rm.rank_within_year, 0) AS actor_rank
FROM 
    ranked_movies rm
WHERE 
    rm.rank_within_year <= 5
ORDER BY 
    rm.production_year DESC, rm.total_actors DESC;
