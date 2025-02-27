WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.movie_id) DESC) AS role_rank,
        COALESCE(mk.keyword, 'Uncategorized') AS movie_keyword
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year, mk.keyword
),
ActorsPerRole AS (
    SELECT
        person_id,
        movie_id,
        COUNT(DISTINCT role_id) AS num_roles,
        SUM(CASE WHEN note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM
        cast_info
    GROUP BY
        person_id, movie_id
),
MoviesWithMinimumRoles AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT a.person_id) AS actor_count
    FROM
        RankedMovies m
    JOIN
        ActorsPerRole a ON m.movie_id = a.movie_id
    WHERE
        m.role_rank = 1 -- Select the top-ranked movie per year
    GROUP BY
        m.movie_id, m.title, m.production_year
    HAVING
        COUNT(DISTINCT a.person_id) > 5 -- Minimum 6 actors per the top-ranked movie
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(n.name, 'Unknown Actor') AS lead_actor,
    COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
    CASE
        WHEN m.actor_count IS NULL THEN 'Not Available'
        ELSE CAST(m.actor_count AS TEXT)
    END AS actor_count
FROM
    MoviesWithMinimumRoles m
LEFT JOIN
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN
    aka_name n ON c.person_id = n.person_id
LEFT JOIN
    movie_keyword k ON m.movie_id = k.movie_id
WHERE
    m.production_year < 2000 OR n.name IS NULL
ORDER BY
    m.production_year DESC,
    m.title;

This SQL query performs the following steps:

1. **CTE `RankedMovies`:** Ranks movies per production year based on the number of roles filled in a count.
2. **CTE `ActorsPerRole`:** Aggregates the number of roles per person and links to each movie, including a count of notes.
3. **CTE `MoviesWithMinimumRoles`:** Filters to keep only movies ranked with the most actors while ensuring they have more than five distinct actors.
4. **Final Select:** Joins various information to provide a list of these filtered movies, including the lead actor (with default value in case of NULL), and ensure keywords are also added with custom handling for NULLs.
5. **WHERE Clause:** Filters out movies that are either pre-2000 or do not have a corresponding actor name.
6. **ORDER BY Clause:** Sorts output by production year (descending) followed by movie title.

This query utilizes outer joins, CTEs, aggregations, and various predicates to demonstrate complex SQL functionalities effectively.
