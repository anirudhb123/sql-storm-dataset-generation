WITH RankedTitles AS (
    SELECT
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
CastMembers AS (
    SELECT
        ci.movie_id,
        an.name AS actor_name,
        rc.role AS role_type
    FROM
        cast_info ci
    JOIN
        aka_name an ON ci.person_id = an.person_id
    JOIN
        role_type rc ON ci.role_id = rc.id
)
SELECT
    rt.production_year,
    COUNT(DISTINCT cm.actor_name) AS unique_actors,
    STRING_AGG(cm.actor_name, ', ') AS actor_list,
    MAX(rt.title_rank) AS max_rank
FROM
    RankedTitles rt
LEFT JOIN
    CastMembers cm ON rt.title = cm.movie_id
WHERE
    rt.title IS NOT NULL
GROUP BY
    rt.production_year
HAVING
    COUNT(cm.actor_name) > 0
ORDER BY
    rt.production_year DESC
LIMIT 10;
