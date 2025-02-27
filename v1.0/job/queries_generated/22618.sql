WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        COUNT(distinct c.movie_id) AS movie_count
    FROM
        cast_info c
    INNER JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        c.person_id, a.name
),
company_details AS (
    SELECT
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies m
    INNER JOIN
        company_name co ON m.company_id = co.id
    INNER JOIN
        company_type ct ON m.company_type_id = ct.id
),
keyword_movies AS (
    SELECT
        mk.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM
        movie_keyword mk
    INNER JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.movie_count,
    cd.company_name,
    cd.company_type,
    km.keywords
FROM
    ranked_movies rm
LEFT JOIN
    actor_info ai ON rm.movie_id = ai.movie_id
LEFT JOIN
    company_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    keyword_movies km ON rm.movie_id = km.movie_id
WHERE
    rm.year_rank <= 5 
    AND (ai.movie_count IS NULL OR ai.movie_count > 0)
    AND (cd.company_type IS NULL OR cd.company_type IN (SELECT ct.kind FROM company_type ct WHERE ct.kind LIKE 'Prod%'))
ORDER BY
    rm.production_year DESC,
    ai.movie_count DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
