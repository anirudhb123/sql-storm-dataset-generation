WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        1 AS hierarchy_level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        mh.hierarchy_level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, movie_keyword_info AS (
    SELECT 
        mk.movie_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
, actor_details AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mk.keywords,
    ad.actor_name,
    ad.total_movies,
    ad.null_notes,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ad.total_movies DESC) AS actor_rank,
    CASE 
        WHEN ad.total_movies > 5 THEN 'Frequent Actor'
        WHEN ad.total_movies BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Rare Actor' 
    END AS actor_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword_info mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    actor_details ad ON ci.person_id = ad.actor_id
ORDER BY 
    mh.production_year DESC, 
    actor_rank
LIMIT 50;

-- Note: Be cautious with correlations and potential NULL logic: 
-- This query considers movies linked recursively while collecting actor data.
-- It shows a combined leaderboard of actors per movie year, categorized by their activity level.
