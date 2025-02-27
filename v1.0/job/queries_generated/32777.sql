WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filtering for movies after the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  -- Limit the recursion depth
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(CAST(ci.nr_order AS INTEGER), 0) AS cast_order,
    ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COALESCE(ci.nr_order, 999) ASC) AS movie_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords,
    CASE 
        WHEN mt.production_year < 2010 THEN 'Old'
        ELSE 'New'
    END AS age_category
FROM 
    aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN movie_hierarchy mh ON ci.movie_id = mh.movie_id
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mh.movie_id = mt.id
WHERE 
    a.name IS NOT NULL 
    AND mt.title IS NOT NULL
GROUP BY 
    a.id, mt.id, mt.title, mt.production_year, ci.nr_order
ORDER BY 
    movie_rank, a.name;


### Explanation of the SQL Query:
1. **Common Table Expression (CTE)**: We first created a recursive CTE called `movie_hierarchy` that captures a hierarchy of movies linked together through the `movie_link` table.
2. **Subquery and Joins**: The main query joins the `aka_name`, `cast_info`, and `aka_title` tables to gather the relevant movie and actor details. Multiple outer joins ensure we gather keywords associated with each movie as needed.
3. **Window Function**: The `ROW_NUMBER()` window function is employed to rank movies within each title based on cast order, allowing for easy identification of the main actors in a given film.
4. **Aggregations and NULL Handling**: The `STRING_AGG` function is used to combine keywords, and `COALESCE` is used to handle potential NULL values for `cast_info.nr_order`.
5. **Complex Expressions**: We have a case statement to categorize movies based on their production year.
6. **Filtering**: The query is outfitted with numerous filtering conditions to ensure relevant data is returned. 

This elaborate structure ensures robustness while allowing performance benchmarking on complex queries and deep relationships in the dataset.

