
WITH movie_details AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(COUNT(DISTINCT ci.id), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS named_roles,
        LISTAGG(DISTINCT a.name, ', ') AS actors
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
movie_info_aggregated AS (
    SELECT
        mi.movie_id,
        LISTAGG(CASE WHEN it.info = 'Plot' THEN mi.info ELSE NULL END, '; ') AS plot,
        LISTAGG(CASE WHEN it.info = 'Genre' THEN mi.info ELSE NULL END, ', ') AS genres
    FROM
        movie_info mi
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY
        mi.movie_id
)
SELECT
    m.title_id,
    m.title,
    m.production_year,
    m.cast_count,
    m.named_roles,
    m.actors,
    mia.plot,
    mia.genres,
    CASE
        WHEN m.cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_presence,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.cast_count DESC) AS rank
FROM
    movie_details m
LEFT JOIN
    movie_info_aggregated mia ON m.title_id = mia.movie_id
WHERE
    m.production_year BETWEEN 2000 AND 2020
ORDER BY
    m.production_year, rank;
