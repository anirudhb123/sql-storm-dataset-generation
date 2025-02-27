WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind SEPARATOR ', ') AS company_types,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actors,
        md.company_types,
        md.keywords
    FROM
        movie_details md
    WHERE
        md.production_year BETWEEN 2000 AND 2023
        AND md.actors IS NOT NULL
)

SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.actors,
    f.company_types,
    f.keywords,
    LENGTH(f.actors) AS actor_count,
    LENGTH(f.company_types) AS company_count,
    LENGTH(f.keywords) AS keyword_count
FROM
    filtered_movies f
ORDER BY
    f.production_year DESC,
    f.title;
