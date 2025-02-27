WITH ranked_movies AS (
    SELECT
        mt.title,
        mt.production_year,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS movie_rank,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY mt.id) AS keyword_count
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year IS NOT NULL
),
actor_aggregates AS (
    SELECT
        ai.person_id,
        COUNT(DISTINCT ac.movie_id) AS total_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS all_movies
    FROM
        cast_info ac
    INNER JOIN
        aka_name ai ON ac.person_id = ai.person_id
    LEFT JOIN
        title at ON ac.movie_id = at.id
    GROUP BY
        ai.person_id
),
complex_attributes AS (
    SELECT
        mc.movie_id,
        COALESCE(COUNT(DISTINCT ct.kind), 0) AS company_count,
        STRING_AGG(DISTINCT co.name, '; ') FILTER (WHERE co.country_code = 'USA') AS us_companies,
        AVG(mk.keyword) OVER (PARTITION BY mc.movie_id) AS avg_keyword_length
    FROM
        movie_companies mc
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    LEFT JOIN
        kind_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    rm.title AS movie_title,
    rm.production_year,
    aa.total_movies AS actor_movie_count,
    aa.all_movies AS actor_movie_list,
    ca.company_count,
    ca.us_companies,
    ca.avg_keyword_length,
    CASE
        WHEN aa.total_movies > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM
    ranked_movies rm
JOIN
    actor_aggregates aa ON rm.movie_rank = 1
JOIN
    complex_attributes ca ON rm.id = ca.movie_id
ORDER BY
    rm.production_year DESC, 
    movie_title ASC
LIMIT 100;
