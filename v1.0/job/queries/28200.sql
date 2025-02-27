WITH movie_details AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title, m.production_year
),
company_details AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM
        movie_companies mc
    JOIN
        company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
movie_summary AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        cd.total_companies,
        cd.company_names,
        md.keywords
    FROM
        movie_details md
    LEFT JOIN
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.cast_names,
    ms.total_companies,
    ms.company_names,
    ms.keywords
FROM
    movie_summary ms
ORDER BY
    ms.production_year DESC, ms.total_cast DESC;
