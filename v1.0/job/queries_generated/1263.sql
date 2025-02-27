WITH ranked_titles AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS year_rank
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(ci.id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    GROUP BY
        ci.movie_id
),
movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rt.title_id,
    rt.title,
    rt.production_year,
    cs.total_cast,
    cs.actors,
    mk.keywords,
    COALESCE(mt.note, 'No Note') AS movie_note
FROM
    ranked_titles rt
LEFT JOIN
    cast_summary cs ON rt.title_id = cs.movie_id
LEFT JOIN
    movie_keywords mk ON rt.title_id = mk.movie_id
LEFT JOIN
    movie_info mt ON rt.title_id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Note')
WHERE
    rt.year_rank <= 5
ORDER BY
    rt.production_year DESC, rt.title;
