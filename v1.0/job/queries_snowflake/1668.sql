
WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        a.id AS movie_id,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM
        aka_title a
    JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.title, a.production_year, a.id
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count_rank
    FROM
        RankedMovies
    WHERE
        actor_count_rank <= 5
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
)
SELECT
    t.title,
    t.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.movie_id) AS total_cast,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.movie_id AND mi.info_type_id = 1) AS has_summary
FROM
    TopMovies t
LEFT JOIN
    MovieKeywords k ON t.movie_id = k.movie_id
WHERE
    t.production_year BETWEEN 2000 AND 2023
ORDER BY
    t.production_year DESC,
    t.actor_count_rank;
