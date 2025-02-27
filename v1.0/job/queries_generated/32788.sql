WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mt.kind_id, 1 AS level
    FROM aka_title AS mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT ml.linked_movie_id, at.title, at.production_year, at.kind_id, mh.level + 1
    FROM movie_link AS ml
    JOIN aka_title AS at ON ml.linked_movie_id = at.movie_id
    JOIN movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
, cast_with_roles AS (
    SELECT ci.person_id, ci.movie_id, ct.kind AS role
    FROM cast_info AS ci
    JOIN comp_cast_type AS ct ON ci.person_role_id = ct.id
)
, actor_movie_count AS (
    SELECT person_id, COUNT(DISTINCT movie_id) AS movie_count
    FROM cast_with_roles
    GROUP BY person_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(a.movie_count) AS avg_movies_per_actor,
    STRING_AGG(DISTINCT CONCAT(ak.name, ' (', ar.role, ')'), '; ') AS actors
FROM movie_keyword AS mk
JOIN movie_hierarchy AS mh ON mk.movie_id = mh.movie_id
LEFT JOIN cast_with_roles AS ar ON mh.movie_id = ar.movie_id
JOIN aka_name AS ak ON ar.person_id = ak.person_id
JOIN actor_movie_count AS a ON a.person_id = ar.person_id
WHERE mk.keyword IS NOT NULL
GROUP BY mk.keyword
HAVING COUNT(DISTINCT mh.movie_id) > 5
ORDER BY movie_count DESC, avg_movies_per_actor DESC
LIMIT 10;

### Query Breakdown:
1. **Recursive CTE (`movie_hierarchy`)**: This CTE gathers movies from the year 2000 onwards and their linked movies.
2. **`cast_with_roles` CTE**: This CTE collects cast information alongside their roles using joins with the `comp_cast_type`.
3. **`actor_movie_count` CTE**: Counts the distinct movies for each actor.
4. **Main Query**: It combines the results from CTEs and joins them with `movie_keyword`, `aka_name`, filtering and aggregating the data to compute the number of movies per keyword, average movies per actor, and list of actors associated with the keywords.
5. **Filters and Aggregates**: The query filters keywords with more than 5 movies, sorts results by movie count and average movies per actor, and limits the output to the top 10.
