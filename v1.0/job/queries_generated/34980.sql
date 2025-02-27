WITH RECURSIVE ActorHierarchy AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        0 AS level
    FROM
        aka_name a
    WHERE
        a.name IS NOT NULL

    UNION ALL

    SELECT
        ca.person_id AS actor_id,
        ak.name AS actor_name,
        ah.level + 1
    FROM
        cast_info ca
        JOIN ActorHierarchy ah ON ca.movie_id IN (
            SELECT
                m.id
            FROM
                title m
                JOIN movie_companies mc ON mc.movie_id = m.id
            WHERE
                mc.company_id IN (
                    SELECT
                        cp.id
                    FROM
                        company_name cp
                    WHERE
                        cp.name LIKE 'Warner%'
                )
        )
        JOIN aka_name ak ON ca.person_id = ak.person_id
)
SELECT
    ah.actor_id,
    ah.actor_name,
    COUNT(DISTINCT ca.movie_id) AS movies_participated,
    AVG(CASE WHEN ti.production_year IS NOT NULL THEN ti.production_year ELSE NULL END) AS average_year,
    COUNT(DISTINCT ti.production_year) AS distinct_years

FROM
    ActorHierarchy ah
    JOIN cast_info ca ON ah.actor_id = ca.person_id
    LEFT JOIN title ti ON ca.movie_id = ti.id

WHERE
    ah.level = 0
    AND (ti.kind_id IN (
        SELECT 
            kind.id
        FROM 
            kind_type kind 
        WHERE 
            kind.kind IN ('movie', 'tv_series')
    ) OR ti.production_year IS NULL)

GROUP BY
    ah.actor_id,
    ah.actor_name
HAVING
    COUNT(DISTINCT ca.movie_id) > 5
ORDER BY
    average_year DESC
LIMIT 100;
