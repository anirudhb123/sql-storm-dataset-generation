WITH movie_details AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        SUM(mo.status_id) AS total_status,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM aka_title mt
    LEFT JOIN complete_cast mo ON mt.id = mo.movie_id
    LEFT JOIN cast_info ci ON mo.subject_id = ci.person_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id, ak.name
),
filtered_movies AS (
    SELECT
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.keyword_count,
        md.total_status,
        md.year_rank
    FROM movie_details md
    WHERE md.keyword_count > 2
      AND md.production_year BETWEEN 1990 AND 2020
      AND md.actor_name IS NOT NULL
),
distinct_actors AS (
    SELECT DISTINCT
        actor_name
    FROM filtered_movies
),
actor_info AS (
    SELECT
        na.name AS actor_real_name,
        na.gender,
        pi.info AS additional_info
    FROM char_name na
    LEFT JOIN person_info pi ON na.imdb_id = pi.person_id
    WHERE na.gender IS NOT NULL
    AND (pi.info IS NOT NULL OR pi.info IS NULL)
)
SELECT
    fm.movie_title,
    fm.production_year,
    fm.actor_name,
    da.actor_real_name,
    da.gender,
    COUNT(ai.additional_info) AS info_count,
    SUM(fm.keyword_count) OVER (PARTITION BY fm.production_year) AS keywords_per_year,
    CASE
        WHEN fm.total_status IS NULL THEN 'No status'
        ELSE 'Status present'
    END AS status_statement
FROM filtered_movies fm
JOIN distinct_actors da ON fm.actor_name = da.actor_name
LEFT JOIN actor_info ai ON da.actor_real_name = ai.actor_real_name
WHERE fm.year_rank <= 5
ORDER BY fm.production_year DESC, fm.actor_name
LIMIT 100;
