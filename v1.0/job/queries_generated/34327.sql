WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, 1 AS level 
    FROM aka_title m
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, mh.level + 1 
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        at.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.id) DESC) AS movie_rank
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE at.production_year IS NOT NULL
    GROUP BY at.id, at.title, at.production_year
    HAVING COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    mh.movie_id,
    mh.title,
    tm.total_cast,
    tm.total_keywords,
    (SELECT AVG(age) 
     FROM (SELECT EXTRACT(YEAR FROM AGE(pi.date_of_birth)) AS age 
           FROM person_info pi 
           WHERE pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = mh.movie_id)) AS ages) AS avg_actor_age
FROM MovieHierarchy mh
LEFT JOIN TopMovies tm ON mh.title = tm.title
WHERE mh.level = 1
ORDER BY tm.total_cast DESC, mh.title;

### Explanation:
1. **CTE (Common Table Expressions)**:
   - `MovieHierarchy`: A recursive CTE that builds a hierarchy of movies starting from those released in 2000 or later. It aggregates linked movies recursively.
   - `TopMovies`: A CTE that calculates the total number of distinct cast members and keywords associated with each movie, filtering out movies with fewer than 5 cast members.

2. **Main Query**:
   - The main SELECT retrieves the movie id and title from the `MovieHierarchy`, along with corresponding totals of cast and keywords from `TopMovies`.
   - It also includes a correlated subquery to compute the average actor age from the `person_info` table for each movie's cast.

3. **Filters and Sorting**:
   - The final results are filtered to include only the top-level movies in the hierarchy and ordered by the total cast count and movie title.

The query explores various SQL features such as complex joins, window functions, aggregate functions, and subqueries to demonstrate performance benchmarking in a comprehensive manner.
