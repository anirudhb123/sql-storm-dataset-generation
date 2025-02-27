WITH actor_movies AS (
    SELECT
        ca.person_id AS actor_id,
        ca.movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT cc.id) AS complete_cast_count
    FROM
        cast_info ca
    JOIN
        title t ON ca.movie_id = t.id
    LEFT JOIN
        complete_cast cc ON ca.movie_id = cc.movie_id AND ca.person_id = cc.subject_id
    GROUP BY
        ca.person_id, ca.movie_id, t.title, t.production_year, t.kind_id
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
movie_details AS (
    SELECT
        am.actor_id,
        am.title,
        am.production_year,
        am.kind_id,
        ks.keywords,
        ks.keyword_count,
        am.complete_cast_count
    FROM
        actor_movies am
    LEFT JOIN
        keyword_summary ks ON am.movie_id = ks.movie_id
)
SELECT
    d.actor_id,
    CONCAT('Movie: ', d.title, ', Year: ', d.production_year, ', Kind ID: ', d.kind_id) AS movie_info,
    d.keywords,
    d.keyword_count,
    d.complete_cast_count
FROM
    movie_details d
WHERE
    d.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%')
ORDER BY
    d.production_year DESC,
    d.keyword_count DESC;
