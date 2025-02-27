WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year,
        COUNT(t.id) OVER (PARTITION BY t.production_year) AS count_titles
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
completed_cast AS (
    SELECT
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS unique_actors,
        SUM(CASE WHEN cc.status_id IS NULL THEN 0 ELSE 1 END) AS valid_status_count
    FROM
        complete_cast cc
    GROUP BY
        cc.movie_id
),
actor_names AS (
    SELECT
        a.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_names
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        a.person_id
)
SELECT
    title.title,
    title.production_year,
    COALESCE(r.rank_year, 0) AS year_rank,
    COALESCE(cc.unique_actors, 0) AS actor_count,
    COALESCE(cc.valid_status_count, 0) AS valid_status,
    COALESCE(an.all_names, 'No Actors') AS actor_names
FROM
    ranked_titles r
LEFT JOIN
    completed_cast cc ON r.title_id = cc.movie_id
LEFT JOIN
    title title ON r.title_id = title.id
LEFT JOIN
    actor_names an ON cc.movie_id = (SELECT id FROM title WHERE title.id = cc.movie_id)
WHERE
    (r.count_titles > 5 OR r.production_year < 2000)
    AND (title.production_year IS NULL OR title.production_year >= 1990)
ORDER BY
    year_rank DESC,
    title.production_year ASC,
    valid_status DESC,
    actor_count DESC
LIMIT 100;
