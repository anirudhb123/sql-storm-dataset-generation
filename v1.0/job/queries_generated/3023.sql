WITH recursive movie_cte AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM
        aka_title m
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title
),
keyword_cte AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
info_cte AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS infos
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)

SELECT
    m.movie_id,
    m.title,
    m.num_actors,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(i.infos, 'No Info Available') AS infos
FROM
    movie_cte m
LEFT JOIN
    keyword_cte k ON m.movie_id = k.movie_id
LEFT JOIN
    info_cte i ON m.movie_id = i.movie_id
WHERE
    m.num_actors > (
        SELECT AVG(actor_count) FROM (
            SELECT COUNT(DISTINCT person_id) AS actor_count
            FROM complete_cast
            GROUP BY movie_id
        ) AS avg_actors
    )
ORDER BY
    m.num_actors DESC
LIMIT 10;
