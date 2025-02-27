WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        array[m.id] AS path
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.path || ml.linked_movie_id
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN title t ON ml.linked_movie_id = t.id
)

SELECT
    ak.person_id,
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_movies,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Role' END) AS last_role,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN title m ON ci.movie_id = m.id
LEFT JOIN movie_keyword mw ON mw.movie_id = m.id
LEFT JOIN keyword kw ON mw.keyword_id = kw.id
LEFT JOIN movie_link ml ON m.id = ml.movie_id
LEFT JOIN MovieHierarchy mh ON mh.movie_id = m.id
GROUP BY ak.person_id, ak.name, m.title, m.production_year
HAVING COUNT(DISTINCT c.id) > 5
ORDER BY COUNT(DISTINCT c.id) DESC, m.production_year DESC
LIMIT 100;

In this elaborated SQL query, we're performing the following actions:

- A **recursive CTE** called `MovieHierarchy` is created to traverse a movie link structure, enabling us to gather all linked movies from the year 2000 onward.
- We perform various **joins** to gather data from actors (`aka_name`), their roles (`cast_info`), movie details (`title`), and associated keywords (`movie_keyword` and `keyword`).
- We use a **LEFT JOIN** to ensure that we also gather movies that might not have associated keywords.
- Aggregate functions like `STRING_AGG()` to collect keywords, `COUNT()` to tally distinct movie appearances, and `AVG()` to calculate average order while also checking for `NULL` values with conditional logic.
- The `HAVING` clause filters results to only include actors with more than 5 movies.
- The results are **ordered** by the count of movies in descending order, along with the production year, and we limit the output to 100 records for performance benchmarking.
