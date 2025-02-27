WITH RankedFilms AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS film_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
ComboMovies AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COALESCE(SUM(ac.actor_count), 0) AS total_actors
    FROM
        movie_keyword mk
    LEFT JOIN
        ActorCount ac ON mk.movie_id = ac.movie_id
    GROUP BY
        m.movie_id
),
FilteredMovies AS (
    SELECT
        mf.*,
        rk.film_rank,
        cm.keyword_count,
        cm.total_actors
    FROM
        RankedFilms rk
    INNER JOIN
        aka_title mf ON rk.title_id = mf.id
    LEFT JOIN
        ComboMovies cm ON mf.id = cm.movie_id
    WHERE
        cm.total_actors > 5
)
SELECT
    f.title,
    f.production_year,
    f.film_rank,
    f.keyword_count,
    f.total_actors,
    COALESCE(k.keyword, 'No Keywords') AS main_keyword
FROM
    FilteredMovies f
LEFT JOIN
    movie_keyword mk ON f.title_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    f.keyword_count > 0
ORDER BY
    f.production_year DESC, f.film_rank;
