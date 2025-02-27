WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(aka.name, 'Unknown') AS director_name,
        LEVEL AS hierarchy_level
    FROM aka_title mt
    LEFT JOIN movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN aka_name aka ON ml.linked_movie_id = aka.movie_id AND aka.name IS NOT NULL
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(aka.name, 'Unknown') AS director_name,
        mh.hierarchy_level + 1
    FROM aka_title mt
    INNER JOIN movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.director_name,
        ROW_NUMBER() OVER (PARTITION BY mh.director_name ORDER BY mh.production_year DESC) AS director_rank
    FROM movie_hierarchy mh
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.director_name,
    CASE 
        WHEN rm.director_rank = 1 THEN 'Latest'
        WHEN rm.director_rank = 2 THEN 'Second Latest'
        ELSE 'Older than Second Latest'
    END AS rank_description,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM ranked_movies rm
LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE rm.production_year IS NOT NULL
GROUP BY 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    rm.director_name, 
    rm.director_rank
HAVING COUNT(kw.id) > 0
ORDER BY 
    rm.production_year DESC, 
    rm.title
LIMIT 100 OFFSET 0;

This SQL query leverages various constructs including recursive common table expressions (CTEs) for movie hierarchies, window functions for ranking, outer joins to include directors even when there are no links, and grouping with HAVING for filtering based on aggregated keyword counts. It reflects complex SQL semantics and interactions, providing rich benchmarking through production year sequences, hierarchical relationships, and keyword categorization.
