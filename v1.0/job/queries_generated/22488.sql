WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year,
        COALESCE(SUM(k.id), 0) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank_per_year <= 5
),
ActorMovieCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        TopMovies tm ON c.movie_id = tm.movie_id
    GROUP BY
        c.movie_id
),
MoviesAndActors AS (
    SELECT
        tm.title,
        tm.production_year,
        AMC.actor_count,
        RANK() OVER (ORDER BY AMC.actor_count DESC) AS actor_rank
    FROM
        TopMovies tm
    JOIN
        ActorMovieCount AMC ON tm.movie_id = AMC.movie_id
)
SELECT
    ma.title,
    ma.production_year,
    ma.actor_count,
    ma.actor_rank,
    (SELECT COUNT(DISTINCT cm.company_id)
     FROM movie_companies cm
     WHERE cm.movie_id = ma.movie_id) AS company_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ') 
     FROM company_name cn
     JOIN movie_companies mc ON mc.company_id = cn.id
     WHERE mc.movie_id = ma.movie_id) AS companies
FROM
    MoviesAndActors ma
WHERE
    ma.actor_count IS NOT NULL
    AND ma.actor_rank <= 3
ORDER BY
    ma.actor_count DESC,
    ma.production_year DESC;

### Explanation:
1. **CTEs (Common Table Expressions)**:
    - **`RankedMovies`**: Ranks movies within their production year and counts associated keywords.
    - **`TopMovies`**: Filters the top five movies for each production year.
    - **`ActorMovieCount`**: Counts unique actors in the movies obtained from the `TopMovies` CTE.
    - **`MoviesAndActors`**: Combines information about movie titles and the count of actors, adding a rank based on the actor count.

2. **Main Query**:
    - Selects movie titles, production years, actor counts, and ranks from the `MoviesAndActors` CTE.
    - Uses correlated subqueries to obtain:
        - The count of companies associated with each movie.
        - A list of company names associated with each movie using `STRING_AGG`.

3. **Order and Filter**:
    - Filters the results to show only movies with non-null actor counts and ranks within the top three by actor count.
    - Orders results primarily by actor count in descending order and by production year in descending order.
