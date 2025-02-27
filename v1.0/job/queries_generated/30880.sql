WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(c.nr_order) AS max_order
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.actor_names,
        ca.actor_count,
        ca.max_order
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
    WHERE 
        mh.production_year >= (SELECT AVG(production_year) FROM aka_title)
        AND coalesce(ca.actor_count, 0) > 5
),
keyword_filter AS (
    SELECT 
        mv.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mvk
    JOIN 
        keyword k ON mvk.keyword_id = k.id
    GROUP BY 
        mv.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    km.keywords
FROM 
    filtered_movies fm
LEFT JOIN 
    keyword_filter km ON fm.movie_id = km.movie_id
ORDER BY 
    fm.production_year DESC,
    fm.actor_count DESC
LIMIT 10;


### Explanation of the Query Components:

- **CTE `movie_hierarchy`**: This recursive CTE builds a hierarchy of movies and episodes, starting from root episodes that do not belong to any other episode.

- **CTE `cast_aggregates`**: This aggregates the cast information for each movie by counting distinct actors, creating an array of distinct actor names, and identifying the maximum order number of the cast.

- **CTE `filtered_movies`**: This filters the movies based on whether they fall above the average production year and have more than five unique actors in the cast. It uses a LEFT JOIN to preserve movies without cast details.

- **CTE `keyword_filter`**: This retrieves keywords associated with movies using a join on the `movie_keyword` table.

- **Final SELECT**: The final selection pulls together the filtered movie data, including title, year, actor count, and associated keywords, ordering the results so the most recent and actor-rich movies show first. 

- **Using `COALESCE`** and `STRING_AGG` functions effectively handle NULL logic and string aggregation for keywords, enhancing the robustness of the query.
