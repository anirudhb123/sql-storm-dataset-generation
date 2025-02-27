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
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
),
top_movies AS (
    SELECT
        movie_id,
        title,
        production_year,
        COUNT(*) OVER (PARTITION BY production_year) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY production_year DESC) AS rn
    FROM
        movie_hierarchy
    WHERE
        level <= 2
),
actors_with_movies AS (
    SELECT
        a.name,
        mt.title,
        mt.production_year
    FROM
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE
        mt.production_year BETWEEN 2000 AND 2023
),
actor_performance AS (
    SELECT 
        a.name AS actor_name,
        AVG(CASE WHEN mt.production_year IS NULL THEN 0 ELSE 1 END) AS performance_score
    FROM 
        actors_with_movies a
    LEFT JOIN 
        top_movies mt ON a.title = mt.title
    GROUP BY 
        a.name
)
SELECT 
    ap.actor_name,
    ap.performance_score,
    COALESCE(tm.title, 'No Movies Found') AS movie_title,
    tm.movie_count,
    CASE
        WHEN ap.performance_score > 0.5 THEN 'High Performer'
        WHEN ap.performance_score = 0.5 THEN 'Average Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    actor_performance ap
LEFT JOIN 
    top_movies tm ON ap.actor_name = (
        SELECT 
            ak.name 
        FROM 
            aka_name ak 
        JOIN 
            cast_info ci ON ak.person_id = ci.person_id 
        WHERE 
            ci.movie_id = tm.movie_id 
        LIMIT 1
    )
WHERE 
    ap.performance_score IS NOT NULL
ORDER BY 
    ap.performance_score DESC, 
    tm.production_year DESC;

This query uses:
- A recursive CTE to build a movie hierarchy based on links between movies
- A window function to count the number of movies produced each year and rank them
- Multiple joins to correlate actor names with the movies they appeared in, filtering for recent films
- Conditional aggregation to assess performance based on the presence of movie data
- A case statement to categorize actors based on their performance scores
- COALESCE to handle NULLs when no movies are found for an actor
