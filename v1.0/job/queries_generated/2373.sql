WITH ranked_movies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    GROUP BY
        ci.person_id
),
high_performers AS (
    SELECT
        an.name,
        am.movie_count
    FROM
        aka_name an
    JOIN actor_movie_count am ON an.person_id = am.person_id
    WHERE
        am.movie_count > (
            SELECT
                AVG(movie_count)
            FROM
                actor_movie_count
        )
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    hp.name AS high_performer,
    mk.keywords
FROM
    ranked_movies rm
LEFT JOIN
    high_performers hp ON hp.movie_count >= 1
LEFT JOIN
    movie_keywords mk ON rm.title_id = mk.movie_id
WHERE
    EXISTS (
        SELECT
            1
        FROM
            complete_cast cc
        WHERE
            cc.movie_id = rm.title_id
            AND cc.status_id IS NOT NULL
    )
ORDER BY
    rm.production_year DESC, rm.title;
