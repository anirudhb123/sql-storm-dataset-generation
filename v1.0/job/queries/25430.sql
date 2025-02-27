WITH top_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        aka_title m
    JOIN
        cast_info c ON m.id = c.movie_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, m.production_year
    ORDER BY
        cast_count DESC
    LIMIT 10
),
detailed_movie_info AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        top_movies tm
    LEFT JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY
        tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.actor_names
),
final_output AS (
    SELECT
        dmi.movie_id,
        dmi.title,
        dmi.production_year,
        dmi.cast_count,
        dmi.actor_names,
        dmi.keywords,
        dmi.company_count,
        CASE
            WHEN dmi.production_year < 2010 THEN 'Classic'
            ELSE 'Modern'
        END AS era,
        REPLACE(dmi.actor_names, ' ', '_') AS formatted_actor_names
    FROM
        detailed_movie_info dmi
)
SELECT
    *
FROM
    final_output
ORDER BY
    production_year DESC, cast_count DESC;
