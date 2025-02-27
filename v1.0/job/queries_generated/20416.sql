WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        SUM(mv_i.info IS NOT NULL) AS has_info,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN
        movie_info mv_i ON mv_i.movie_id = t.movie_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
        AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature')))
    GROUP BY
        t.id
    HAVING
        COUNT(DISTINCT ci.person_id) > 2
),

filter_castings AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    WHERE
        ci.note IS NULL OR ci.note != 'uncredited'
),

final_results AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        f.person_id,
        f.role_order,
        CASE 
            WHEN f.role_order IS NULL THEN 'no_roles'
            WHEN f.role_order = 1 THEN 'lead_role'
            ELSE 'supporting_role'
        END AS role_type
    FROM
        movie_details md
    LEFT JOIN
        filter_castings f ON f.movie_id = md.movie_id
)

SELECT
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.cast_names,
    COALESCE(fr.person_id, 'No cast found') AS cast_member,
    fr.role_type
FROM
    final_results fr
WHERE
    fr.total_keywords > 0
ORDER BY
    fr.production_year DESC,
    fr.title ASC;
