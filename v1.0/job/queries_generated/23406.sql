WITH RecursiveMovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(m.parent_id, 0) AS parent_id  -- Assuming a parent_id column for hierarchy
    FROM
        aka_title m
    WHERE
        m.id IN (SELECT movie_id FROM complete_cast WHERE status_id = 1)

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.parent_id
    FROM
        aka_title m
    JOIN RecursiveMovieHierarchy r
        ON m.id = r.parent_id
)

, ActorMovieInfo AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order AS cast_order,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
    FROM
        aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE
        a.name IS NOT NULL
)

, KeywordCounts AS (
    SELECT
        t.id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY
        t.id
)

SELECT
    COALESCE(actor_movie.actor_name, 'Unknown Actor') AS actor_name,
    actor_movie.movie_title,
    actor_movie.production_year,
    actor_movie.cast_order,
    k.keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    ARRAY_AGG(DISTINCT c.kind) FILTER (WHERE c.kind IS NOT NULL) AS company_kinds,
    MAX(CASE WHEN keyword.keyword IS NULL THEN 'No Keyword' ELSE keyword.keyword END) AS first_keyword
FROM
    ActorMovieInfo actor_movie
LEFT JOIN
    KeywordCounts k ON actor_movie.movie_title = (SELECT title FROM aka_title WHERE id = k.title_id)
LEFT JOIN 
    movie_companies mc ON actor_movie.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword keyword ON actor_movie.movie_title = (SELECT title FROM aka_title WHERE id = keyword.movie_id)
LEFT JOIN 
    RecursiveMovieHierarchy rm ON actor_movie.movie_title = rm.movie_title
WHERE
    actor_movie.cast_order IS NOT NULL OR actor_movie.cast_order IS DISTINCT FROM NULL
GROUP BY
    actor_movie.actor_name, actor_movie.movie_title, actor_movie.production_year, 
    actor_movie.cast_order, k.keyword_count
HAVING
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY
    actor_movie.production_year DESC,
    actor_movie.cast_order ASC
LIMIT 100;

### Explanation:
1. **CTEs (Common Table Expressions)**: 
   - `RecursiveMovieHierarchy` builds a hierarchy of movies, assuming a `parent_id` column to support nested relationships.
   - `ActorMovieInfo` gathers actor details connected to their movies using `JOIN`s.
   - `KeywordCounts` counts the number of keywords associated with each movie.

2. **LEFT `JOIN`**: Used to make sure all actors and their movies are represented even if there are missing matching records in other tables.

3. **Window Function (`RANK()`)**: Calculates the rank of each actor's role in each movie.

4. **Complex Aggregations**: Uses `ARRAY_AGG` along with a `FILTER` clause to return unique company types associated with each movie.

5. **Complicated NULL Logic**: COALESCE, NULL handling in SELECT statements and HAVING clause ensures filtration of data-centric outputs through conditional checks.

6. **DISTINCT, GROUP BY and HAVING**: Combined clauses for ensuring uniqueness in results and filtering based on company counts.

7. **Array and String Functions**: Displays results in a structured format with fallback values for missing keywords.

This query serves to benchmark performance across multiple join operations, subqueries, and aggregations, while also being rich in complexity and potential edge cases involving NULL values and hierarchy structures.
