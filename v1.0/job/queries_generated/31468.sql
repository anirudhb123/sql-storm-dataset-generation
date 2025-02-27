WITH RECURSIVE MovieHierarchy AS (
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
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mw.keyword) AS keyword_count,
    AVG(mv.movie_avg) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY mh.level DESC) AS rank
FROM 
    aka_name a
INNER JOIN 
    cast_info c ON a.person_id = c.person_id
INNER JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        AVG(info::numeric) AS movie_avg 
    FROM 
        movie_info 
    WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        movie_id
) mv ON mh.movie_id = mv.movie_id
WHERE 
    a.name IS NOT NULL
    AND mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT mw.keyword) >= 3
ORDER BY 
    average_rating DESC, rank ASC;

### Explanation:
- A recursive common table expression (CTE) named `MovieHierarchy` is created to generate a hierarchy of movies linked by the `movie_link` table, starting from movies produced in or after 2000.
- The main query joins the CTE with the `aka_name`, `cast_info`, and other relevant tables to gather details about actors and their roles in the movies.
- `LEFT JOIN` is used to include all movies, even those without associated keywords. 
- The average rating of movies is calculated using a subquery that filters information by type, demonstrating a practical use of aggregation functions and aggregating ratings.
- The `GROUP BY` clause structures the output by actor name, movie title, and production year, while `HAVING` ensures that only entries with three or more keywords are included.
- `ROW_NUMBER()` window function is utilized to rank actors based on their deepest level of movie hierarchy, allowing for flexible performance assessments.
- The results are ordered by average rating in descending order and actor ranking in ascending order, showcasing high-rated performances with significant keyword associations.
