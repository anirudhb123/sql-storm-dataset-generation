WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        title m
        JOIN movie_info mi ON m.id = mi.movie_id
        JOIN movie_keyword mk ON m.id = mk.movie_id
        JOIN keyword kw ON mk.keyword_id = kw.id
        JOIN complete_cast cc ON m.id = cc.movie_id
        JOIN cast_info ci ON cc.subject_id = ci.id
        JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
        AND m.production_year >= 2000
    GROUP BY
        m.id,
        m.title,
        m.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actors,
    tm.keywords
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.actor_count DESC;
