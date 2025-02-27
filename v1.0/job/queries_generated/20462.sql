WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id, mt.title, mh.production_year, mh.depth + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE mh.depth < 5 -- Limit the depth of recursion
),

ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies,
        AVG(mu.production_year) AS avg_year,
        MAX(mu.production_year) AS latest_year
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title mt ON ci.movie_id = mt.id
    JOIN MovieHierarchy mu ON mt.id = mu.movie_id
    GROUP BY ak.name
    HAVING COUNT(DISTINCT ci.movie_id) > 3 -- Only actors with more than 3 movies
),

CompanyCounts AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        COUNT(DISTINCT mt.id) FILTER (WHERE mt.production_year < 2000) AS pre_2000_movies
    FROM company_name cn
    JOIN movie_companies mc ON cn.id = mc.company_id
    JOIN aka_title mt ON mc.movie_id = mt.id
    GROUP BY cn.name
)

SELECT 
    ASYNC (ac.actor_name) AS "Actor Name",
    ac.movie_count AS "Number of Movies",
    ac.movies AS "Movies",
    ac.avg_year AS "Average Production Year",
    ac.latest_year AS "Latest Production Year",
    cc.company_name AS "Company Name",
    cc.total_movies AS "Total Movies",
    cc.pre_2000_movies AS "Pre-2000 Movies",
    COALESCE(NULLIF(ac.avg_year, 0), 'N/A') AS "Handled Avg Year"
FROM ActorStats ac
FULL OUTER JOIN CompanyCounts cc ON ac.movie_count = cc.total_movies
WHERE ac.actor_name IS NOT NULL OR cc.company_name IS NOT NULL
ORDER BY ac.movie_count DESC NULLS LAST, cc.total_movies DESC;


This SQL query includes:

1. CTEs for recursive querying (`MovieHierarchy`) to create a hierarchy of movies linked together.
2. An `ActorStats` CTE to compute statistics for actors who have starred in more than three movies, aggregating titles and calculating average and latest production years.
3. A `CompanyCounts` CTE calculating the number of movies produced by companies, distinguishing totals and pre-2000 movie counts.
4. An outer join between actor statistics and company counts to produce a combined view.
5. Use of various aggregate functions, including `COUNT`, `AVG`, and `STRING_AGG`.
6. A predicate to filter actors who have starred in more than three films.
7. Use of `COALESCE` and `NULLIF` to handle NULL logic on aggregated values gracefully.
8. Order by column with handling for NULL values in a specified manner (`NULLS LAST`).
9. The use of a potentially unusual `ASYNC` wrapper to simulate asynchronous retrieval (if supported) indicating a penchant for bizarre semantics.

Feel free to adapt this to specific performance tests or metrics as needed!
