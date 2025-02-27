
WITH movie_data AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM
        aka_title m
    JOIN
        cast_info ci ON m.id = ci.movie_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        m.id, m.title, m.production_year
),
info_data AS (
    SELECT
        movie_id,
        MAX(info) AS summary_info
    FROM
        movie_info
    WHERE
        info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY
        movie_id
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    COALESCE(id.summary_info, 'No summary available') AS summary_info
FROM
    movie_data md
LEFT JOIN
    info_data id ON md.movie_id = id.movie_id
ORDER BY
    md.production_year DESC,
    md.title ASC
LIMIT 100;
