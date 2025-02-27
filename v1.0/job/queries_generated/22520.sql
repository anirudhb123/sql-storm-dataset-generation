WITH RECURSIVE rated_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        COUNT(DISTINCT c.person_id) AS total_cast_members
    FROM aka_title t
    LEFT JOIN cast_info c ON c.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id
    HAVING COUNT(DISTINCT c.person_id) > 2
),
popular_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_featured
    FROM aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    GROUP BY a.id, a.name
    HAVING COUNT(DISTINCT ci.movie_id) > 5
),
movie_details AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(m.movie_count, 0) AS movie_count,
        s.name AS starring_actor,
        ROW_NUMBER() OVER (PARTITION BY r.movie_id ORDER BY a.movies_featured DESC) AS rn
    FROM rated_movies r
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            COUNT(*) AS movie_count
        FROM cast_info ci
        JOIN popular_actors a ON a.actor_id = ci.person_id
        GROUP BY ci.movie_id
    ) m ON m.movie_id = r.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = r.movie_id
    LEFT JOIN aka_name s ON s.person_id = ci.person_id
    LEFT JOIN popular_actors a ON a.actor_id = ci.person_id
    WHERE s.id IS NOT NULL OR (s.name IS NULL AND r.production_year < 2000)
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_count,
    md.starring_actor,
    CASE 
        WHEN md.rn = 1 THEN 'Lead Actor'
        WHEN md.rn BETWEEN 2 AND 3 THEN 'Supporting Actor'
        ELSE 'Background Actor'
    END AS actor_role
FROM movie_details md
WHERE md.movie_count > 0
ORDER BY md.production_year DESC, md.movie_count DESC;

This SQL query contains several advanced constructs:
1. **Common Table Expressions (CTEs)**: This query contains three CTEs, `rated_movies`, `popular_actors`, and `movie_details`. 
2. **Outer Joins**: In the `movie_details` CTE, LEFT JOINs are utilized to maintain all movie records, even if they do not have associated cast members.
3. **Window Functions**: The `ROW_NUMBER()` function is applied to partition the data by `movie_id` and order by the number of movies featured for the actor.
4. **Complicated Predicates**: The WHERE clause in the outer query includes a NULL check intertwined with a comparison against a year threshold.
5. **Correlated Subqueries**: Aggregation in `movie_count` is done through grouping depending on correlated actors.
6. **COALESCE**: This function is usefully employed to handle cases where there are no associated movie counts.
7. **CASE Statement**: Labels actors based on their roles depending on the count of movies they've featured in.

This elaborate SQL showcases the complexity and finer details of querying in a normalized schema context while adhering to various SQL semantics.
