WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, t.title, t.production_year, 1 AS level
    FROM cast_info ci
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')

    UNION ALL

    SELECT ci.person_id, t.title, t.production_year, ah.level + 1
    FROM cast_info ci
    JOIN aka_title t ON ci.movie_id = t.movie_id
    JOIN ActorHierarchy ah ON ci.person_id = ah.person_id
    WHERE ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
)

SELECT
    ak.name,
    COUNT(DISTINCT ah.movie_id) AS movie_count,
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(ah.production_year) AS years_since_last_movie,
    STRING_AGG(DISTINCT ak.name || ' (' || ah.production_year || ')', ', ') AS movies,
    RANK() OVER (ORDER BY COUNT(DISTINCT ah.movie_id) DESC) AS actor_rank
FROM
    aka_name ak
JOIN
    ActorHierarchy ah ON ak.person_id = ah.person_id
LEFT JOIN
    movie_info mi ON ah.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    ah.production_year >= (EXTRACT(YEAR FROM CURRENT_DATE) - 10)
GROUP BY
    ak.id
HAVING
    COUNT(DISTINCT ah.movie_id) > 5 AND
    NULLIF(MAX(mi.info), '') IS NOT NULL
ORDER BY
    actor_rank, years_since_last_movie DESC;

### Explanation:
- **CTE**: A recursive CTE `ActorHierarchy` is defined to gather all movies that actors have participated in recursively.
- **Joins**: It joins the `cast_info` to `aka_title` using the `movie_id`, and it joins again on itself to track actors' roles in multiple movies.
- **Aggregations**: Counts distinct movies per actor and accumulates movie titles and their corresponding years.
- **Window Function**: Implements a `RANK()` window function to rank actors based on the count of movies they have appeared in.
- **Calculations**: Calculates how many years it has been since each actor's last movie.
- **Filtering**: Restricts results to actors who have appeared in the last ten years and only includes those with considerable movie counts.
- **NULL Handling**: Uses `NULLIF` to ensure that only actors with valid movie ratings are considered.
- **Ordering**: Results are ordered first by rank, and in case of ties, by years since their last movie.
