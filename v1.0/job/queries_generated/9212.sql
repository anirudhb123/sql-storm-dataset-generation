WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type
    FROM
        title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.id
    JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type c ON mc.company_type_id = c.id
    GROUP BY
        t.id, t.title, t.production_year, c.kind
)
SELECT
    movie_title,
    production_year,
    actors,
    keywords,
    COUNT(DISTINCT actors) OVER (PARTITION BY production_year) AS actor_count_per_year
FROM
    MovieDetails
WHERE
    production_year > 2000
ORDER BY
    production_year DESC, movie_title;
