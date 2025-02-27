WITH movie_details AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        GROUP_CONCAT(DISTINCT mw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        title t
    JOIN
        aka_title at ON t.id = at.movie_id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN
        keyword k ON mw.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, a.name, t.title, t.production_year
),
ranked_movies AS (
    SELECT
        title,
        production_year,
        actor_name,
        companies,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM
        movie_details
)
SELECT
    rank,
    title,
    production_year,
    actor_name,
    companies,
    keywords,
    cast_count
FROM
    ranked_movies
WHERE
    rank <= 10
ORDER BY
    rank;
