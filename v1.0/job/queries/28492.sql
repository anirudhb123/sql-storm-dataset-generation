
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title t
        JOIN cast_info c ON t.id = c.movie_id
        JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
    HAVING
        COUNT(c.id) > 5 
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        RANK() OVER (ORDER BY actor_count DESC, production_year DESC) AS rnk
    FROM
        RankedMovies
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    mk.keywords
FROM
    TopMovies tm
LEFT JOIN
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE
    tm.rnk <= 10 
ORDER BY
    tm.actor_count DESC;
