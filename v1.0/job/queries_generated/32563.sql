WITH RECURSIVE movie_hierarchy AS (
    -- CTE to find all linked movies (sequel/prequel relationships)
    SELECT 
        ml.movie_id AS base_movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    UNION ALL
    SELECT 
        mh.base_movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
),
movie_cast AS (
    -- CTE to get a list of movies with cast details
    SELECT 
        t.id AS movie_id,
        t.title,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
),
aggregated_data AS (
    -- CTE to aggregate movie information
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        MAX(t.production_year) AS latest_year
    FROM 
        title t
    LEFT JOIN 
        movie_cast c ON t.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id
),
final_result AS (
    -- Final selection query with outer join on movie hierarchy
    SELECT
        ad.movie_id,
        ad.title,
        ad.total_actors,
        ad.actor_names,
        mh.linked_movie_id,
        mh.level AS relationship_level,
        CASE 
            WHEN ad.latest_year <= 2000 THEN 'Old'
            WHEN ad.latest_year <= 2010 THEN 'Mid'
            ELSE 'Recent'
        END AS movie_age_category
    FROM 
        aggregated_data ad
    LEFT JOIN 
        movie_hierarchy mh ON ad.movie_id = mh.base_movie_id
)
-- Final output with filtering and sorting
SELECT 
    movie_id,
    title,
    total_actors,
    actor_names,
    linked_movie_id,
    relationship_level,
    movie_age_category
FROM 
    final_result
WHERE 
    total_actors > 5
ORDER BY 
    movie_age_category DESC, total_actors DESC;
