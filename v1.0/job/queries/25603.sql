WITH movie_details AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS actor_name
    FROM
        title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        cast_info ci ON t.id = ci.movie_id
    JOIN
        aka_name p ON ci.person_id = p.person_id
    WHERE
        t.production_year > 2000
        AND k.keyword LIKE '%action%'
),
actor_summary AS (
    SELECT
        actor_name,
        COUNT(movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies
    FROM
        movie_details
    GROUP BY
        actor_name
)
SELECT
    actor_name,
    movie_count,
    movies,
    (SELECT COUNT(DISTINCT company_name) FROM movie_details) AS total_companies_involved,
    (SELECT COUNT(DISTINCT movie_keyword) FROM movie_details) AS total_keywords
FROM
    actor_summary
ORDER BY
    movie_count DESC
LIMIT 10;
