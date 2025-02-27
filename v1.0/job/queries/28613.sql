WITH movie_data AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN
        name c ON c.id = ci.person_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        t.id, t.title, t.production_year
),
company_data AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON cn.id = mc.company_id
    JOIN
        company_type ct ON ct.id = mc.company_type_id
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.cast_names,
    md.keyword_count,
    cd.companies,
    cd.company_types
FROM
    movie_data md
LEFT JOIN
    company_data cd ON cd.movie_id = md.movie_id
WHERE
    md.production_year > 2000
ORDER BY
    md.production_year DESC, md.title;
