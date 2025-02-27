WITH RECURSIVE movie_hierarchy AS (
    -- First, we identify the root movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    -- Then we find all episodes for each movie, building the hierarchy
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
movie_cast AS (
    -- Collect all cast information for the movies
    SELECT 
        mk.movie_id,
        ak.name AS actor_name,
        ak.imdb_index AS actor_imdb_index,
        cc.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY cc.nr_order) AS actor_order
    FROM 
        cast_info cc
    JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    JOIN 
        aka_title mk ON cc.movie_id = mk.id
),
movie_info AS (
    -- Aggregate movie information and filter based on conditions
    SELECT 
        mh.movie_id,
        mh.title,
        STRING_AGG(DISTINCT mk.actor_name, ', ') AS cast_list,
        COUNT(DISTINCT mk.actor_name) AS actor_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title
    HAVING 
        COUNT(DISTINCT mk.actor_name) > 2  -- Only interested in movies with more than 2 actors
)
SELECT 
    mi.title,
    mi.actor_count,
    CASE
        WHEN mi.actor_count > 10 THEN 'Large Cast'
        WHEN mi.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size_category,
    COALESCE(mi.cast_list, 'No actors available') AS actor_names,
    (
        SELECT COUNT(DISTINCT mc.company_id)
        FROM movie_companies mc
        WHERE mc.movie_id = mi.movie_id
    ) AS company_count
FROM 
    movie_info mi
ORDER BY 
    mi.actor_count DESC, 
    mi.title;
