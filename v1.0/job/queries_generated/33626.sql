WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        a.id AS person_id,
        a.name AS actor_name,
        m.title AS movie_title,
        COALESCE(m.production_year, 0) AS production_year,
        1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title m ON c.movie_id = m.movie_id
    WHERE m.production_year > 2000

    UNION ALL

    SELECT 
        ca.id AS cast_id,
        a.id AS person_id,
        a.name AS actor_name,
        m.title AS movie_title,
        COALESCE(m.production_year, 0) AS production_year,
        ah.level + 1
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    JOIN aka_title m ON ca.movie_id = m.movie_id
    JOIN ActorHierarchy ah ON ca.movie_id = ah.movie_id AND ca.person_id <> ah.person_id
)

SELECT 
    ah.actor_name,
    COUNT(ah.cast_id) AS total_movies,
    MAX(ah.production_year) AS most_recent_year,
    STRING_AGG(DISTINCT ah.movie_title, '; ') AS movie_titles,
    RANK() OVER (ORDER BY COUNT(ah.cast_id) DESC) AS actor_rank
FROM ActorHierarchy ah
GROUP BY ah.actor_name
HAVING COUNT(ah.cast_id) > 5
ORDER BY actor_rank;

WITH MovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
    HAVING COUNT(DISTINCT c.person_id) >= 3
)

SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.actor_count,
    COALESCE(m.production_year - LAG(m.production_year) OVER (ORDER BY m.production_year), 0) AS year_difference
FROM MovieInfo m
WHERE m.production_year IS NOT NULL
ORDER BY m.production_year DESC
LIMIT 10;

### Query Breakdown:
1. **Recursive CTE** (`ActorHierarchy`): This CTE creates a hierarchy of actors based on their collaboration in movies released after 2000. It uses a self-join to link actors who worked together on the same project.
2. **Aggregations**: The CTE gathers valuable statistics on each actor's movies, including the total number of movies they have acted in, the most recent movie's production year, and a concatenated list of movie titles.
3. **Final Selection**: The outer query filters actors with more than five movies, ranks them, and orders them accordingly.
4. **Additional CTE** (`MovieInfo`): Aggregates movie titles created, finds the count of distinct actors for each movie, and gathers related keywords. 
5. **LAG Window Function**: Used to compute the year difference between each movie and its predecessor based on production year.
6. **Final Output**: Displays the movie titles, production year, keywords, actor count, and the computed year difference for movies with at least three actors, limited to the last 10 records. 

This query aims to benchmark performance by combining various SQL concepts, such as CTEs, subqueries, window functions, and string aggregation, while also performing aggregations and joins across multiple tables.
