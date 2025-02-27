WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
    ORDER BY
        m.production_year DESC
),
info_summary AS (
    SELECT
        d.movie_id,
        d.movie_title,
        d.production_year,
        COALESCE(NULLIF(d.actors, ''), 'Unknown') AS actors,
        COALESCE(NULLIF(d.keywords, ''), 'None') AS keywords,
        COALESCE(NULLIF(d.companies, ''), 'N/A') AS companies,
        ROW_NUMBER() OVER (PARTITION BY d.production_year ORDER BY d.movie_title) AS rank
    FROM
        movie_details d
)
SELECT
    *
FROM
    info_summary
WHERE
    rank <= 5
ORDER BY
    production_year DESC, movie_title;
