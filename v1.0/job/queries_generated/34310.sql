WITH RECURSIVE actor_hierarchy AS (
    SELECT a.person_id, a.name, 0 AS level
    FROM aka_name a
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT a.person_id, CONCAT(a.name, ' (Supporting Role)') AS name, ah.level + 1
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN actor_hierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info ci WHERE ci.person_id = ah.person_id LIMIT 1)
    WHERE c.note IS NOT NULL
      AND ah.level < 5  -- limit recursion to 5 levels
),

movies_with_keywords AS (
    SELECT m.id AS movie_id, m.title, k.keyword
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year >= 2000 
      AND (k.keyword IS NULL OR k.keyword LIKE '%action%')  -- action movies or no keywords
),

completed_movie_info AS (
    SELECT m.movie_id, COUNT(DISTINCT ci.person_id) AS total_actors,
           STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movies_with_keywords m
    LEFT JOIN complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.movie_id, m.title
),

ranked_movies AS (
    SELECT movie_id, title, total_actors,
           ROW_NUMBER() OVER (PARTITION BY total_actors ORDER BY title) AS rank
    FROM completed_movie_info
)

SELECT r.title, r.total_actors, ah.name AS leading_actor, r.rank
FROM ranked_movies r
LEFT JOIN actor_hierarchy ah ON r.movie_id = (
    SELECT DISTINCT c.movie_id
    FROM cast_info c
    WHERE c.person_id = ah.person_id
    LIMIT 1
)
WHERE r.total_actors > 1  -- at least 2 actors required
ORDER BY r.rank, r.total_actors DESC;

### Explanation:
1. **Recursive CTE (`actor_hierarchy`)**: Fetches actors recursively, simulating a hierarchy based on their roles, limiting the levels to 5.
2. **Movies with Keywords (`movies_with_keywords`)**: Filters movies produced after the year 2000 that either have keywords related to 'action' or no keywords at all.
3. **Completed Movie Info (`completed_movie_info`)**: Aggregates movie data including actor names and associated keywords, while counting distinct actors.
4. **Ranked Movies (`ranked_movies`)**: Ranks the movies based on the number of actors.
5. **Final SELECT**: Joins the ranked movies with the leading actors from the hierarchical data, filtering for movies with at least 2 actors, and orders the results by rank and number of actors.

This query is indicative of complex SQL functionalities and explores various aspects like CTEs, joins, aggregations, string functions, and filtering logic.
