WITH RECURSIVE movie_hierarchy AS (
    -- Start with the top-level movies (those without a parent)
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursively find the child episodes
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM title t
    JOIN movie_hierarchy mh ON t.episode_of_id = mh.movie_id
),
ranked_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT r.actor_name) AS total_actors,
        STRING_AGG(r.actor_name, ', ') AS actor_list
    FROM movie_hierarchy mh
    LEFT JOIN ranked_actors r ON mh.movie_id = r.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
    HAVING COUNT(DISTINCT r.actor_name) > 2
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.actor_list,
    CASE 
        WHEN fm.production_year < 2000 THEN 'Classic'
        WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_category,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = fm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) AS budget_info_count
FROM filtered_movies fm
LEFT JOIN movie_info mi ON fm.movie_id = mi.movie_id
WHERE mi.note IS NULL -- Only consider movies without additional notes
ORDER BY fm.production_year DESC, fm.total_actors DESC;
