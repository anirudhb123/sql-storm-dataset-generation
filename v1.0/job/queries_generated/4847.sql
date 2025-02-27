WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
),
TopMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.avg_order,
        RANK() OVER (ORDER BY md.actor_count DESC, md.production_year ASC) AS rank
    FROM
        MovieDetails md
    WHERE
        md.actor_count > 0
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.avg_order,
    array_agg(DISTINCT ak.name SEPARATOR ', ') AS actors
FROM
    TopMovies tm
LEFT JOIN
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN
    aka_name ak ON cc.subject_id = ak.person_id
WHERE
    tm.rank <= 10
GROUP BY
    tm.movie_id, tm.title, tm.production_year, tm.actor_count, tm.avg_order
ORDER BY
    tm.actor_count DESC, tm.production_year ASC;
