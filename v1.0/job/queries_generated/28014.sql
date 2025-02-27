WITH movie_statistics AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        MAX(CASE WHEN ti.info_type_id = 1 THEN mi.info END) AS summary_info,
        MAX(CASE WHEN ti.info_type_id = 2 THEN mi.info END) AS ratings_info
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        info_type ti ON mi.info_type_id = ti.id
    GROUP BY
        m.id, m.title, m.production_year
),
ranked_movies AS (
    SELECT
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS cast_rank,
        RANK() OVER (ORDER BY production_year DESC) AS year_rank
    FROM
        movie_statistics
)
SELECT
    movie_id,
    movie_title,
    production_year,
    cast_count,
    cast_names,
    keywords,
    companies,
    summary_info,
    ratings_info,
    cast_rank,
    year_rank
FROM
    ranked_movies
WHERE
    cast_count > 5
ORDER BY
    cast_rank, production_year DESC;
