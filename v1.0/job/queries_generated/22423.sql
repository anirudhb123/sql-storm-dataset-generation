WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM
        movie_link AS ml
    JOIN
        aka_title AS at ON ml.movie_id = at.id
    JOIN
        movie_hierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE
        mh.level < 3
),

actor_movie AS (
    SELECT
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ci.nr_order) AS rn
    FROM
        aka_name AS a
    JOIN
        cast_info AS ci ON a.person_id = ci.person_id
    WHERE
        a.name IS NOT NULL
),

movie_rating AS (
    SELECT
        mi.movie_id,
        AVG(CASE WHEN mi.info_type_id = 5 THEN CAST(mi.info AS DECIMAL) END) AS avg_rating
    FROM
        movie_info AS mi
    GROUP BY
        mi.movie_id
),

final_result AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        ar.name AS actor_name,
        mr.avg_rating,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mr.avg_rating DESC) AS actor_rank
    FROM
        movie_hierarchy AS mh
    LEFT JOIN
        actor_movie AS ar ON mh.movie_id = ar.movie_id AND ar.rn = 1
    LEFT JOIN
        movie_rating AS mr ON mh.movie_id = mr.movie_id
)

SELECT
    fr.movie_id,
    fr.title,
    fr.production_year,
    CASE 
        WHEN fr.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%') THEN 'Drama'
        WHEN fr.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Action%') THEN 'Action'
        ELSE 'Other'
    END AS genre_classification,
    COALESCE(fr.actor_name, 'Unknown') AS lead_actor,
    COALESCE(fr.avg_rating, 0.0) AS average_rating,
    COUNT(DISTINCT COALESCE(CAST(ci.note AS VARCHAR), 'No Note')) AS unique_notes
FROM
    final_result AS fr
LEFT JOIN
    complete_cast AS cc ON fr.movie_id = cc.movie_id
LEFT JOIN
    cast_info AS ci ON cc.subject_id = ci.id
WHERE
    fr.actor_rank = 1
GROUP BY
    fr.movie_id, fr.title, fr.production_year, fr.kind_id, fr.actor_name, fr.avg_rating
ORDER BY
    fr.avg_rating DESC NULLS LAST,
    fr.production_year ASC
LIMIT 50;
