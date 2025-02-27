
WITH ranked_titles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
actor_details AS (
    SELECT
        n.id AS actor_id,
        n.name,
        n.gender,
        ARRAY_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM
        name n
    JOIN
        cast_info ci ON n.id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY
        n.id, n.name, n.gender
),
movies_with_actor_count AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ac.actor_count,
        COALESCE(a.gender, 'Unknown') AS lead_actor_gender
    FROM
        aka_title mt
    LEFT JOIN
        actor_counts ac ON mt.id = ac.movie_id
    LEFT JOIN LATERAL (
        SELECT
            ad.gender
        FROM
            actor_details ad
        WHERE
            ad.actor_id = (SELECT ci.person_id
                           FROM cast_info ci
                           WHERE ci.movie_id = mt.id
                           ORDER BY ci.nr_order LIMIT 1)
        LIMIT 1
    ) a ON TRUE
)
SELECT
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.lead_actor_gender,
    CASE
        WHEN mw.actor_count IS NULL THEN 'No Actors'
        WHEN mw.actor_count = 0 THEN 'No Actors'
        WHEN mw.actor_count > 1 THEN 'Multiple Actors'
        ELSE 'Single Actor'
    END AS actor_summary,
    CASE 
        WHEN mw.production_year > 2000 AND mw.actor_count IS NOT NULL THEN 
            'Modern Film'
        WHEN mw.production_year <= 2000 AND mw.actor_count IS NOT NULL THEN 
            'Classic Film'
        ELSE 
            'Unknown Era'
    END AS film_era
FROM
    movies_with_actor_count mw
LEFT JOIN
    ranked_titles rt ON mw.movie_id = rt.title_id AND rt.title_rank = 1
WHERE
    mw.actor_count IS NULL OR mw.actor_count > 1
ORDER BY
    mw.production_year DESC,
    mw.title ASC;
