WITH RECURSIVE actor_hierarchy AS (
    SELECT
        ci.person_id,
        COUNT(ci.movie_id) AS movie_count
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    GROUP BY
        ci.person_id
),
movie_details AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        array_agg(DISTINCT ak.name) AS actor_names
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mt.id
),
keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
company_info AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(ai.movie_count, 0) AS actor_count,
    COALESCE(ki.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(ci.company_names, 'No Companies') AS production_companies
FROM
    movie_details md
LEFT JOIN
    actor_hierarchy ai ON ai.person_id IN (
        SELECT DISTINCT person_id FROM cast_info WHERE movie_id = md.movie_id
    )
LEFT JOIN
    keyword_summary ki ON md.movie_id = ki.movie_id
LEFT JOIN
    company_info ci ON md.movie_id = ci.movie_id
WHERE
    md.production_year >= 2000
ORDER BY
    md.production_year DESC,
    md.title;

-- Performance Benchmarking:
-- Here we use various constructs such as Common Table Expressions (CTEs),
-- LEFT JOINs, COALESCE for NULL handling, STRING_AGG for string aggregation,
-- DISTINCT, and correlated subqueries to extract relevant movie data.
