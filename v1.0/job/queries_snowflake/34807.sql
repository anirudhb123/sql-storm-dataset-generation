WITH RECURSIVE PopularTitles AS (
    SELECT
        title.id AS title_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM
        title
    INNER JOIN
        cast_info ON title.id = cast_info.movie_id
    GROUP BY
        title.id, title.title, title.production_year
    HAVING
        COUNT(DISTINCT cast_info.person_id) >= 5
),
RecentTitles AS (
    SELECT
        title.id AS title_id,
        title.title,
        title.production_year,
        title.kind_id,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS rn
    FROM
        title
    WHERE
        title.production_year >= 2020
),
ActorRoles AS (
    SELECT
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.role_id) AS num_roles
    FROM
        aka_name
    LEFT JOIN
        cast_info ON aka_name.person_id = cast_info.person_id
    GROUP BY
        aka_name.person_id, aka_name.name
    HAVING
        COUNT(DISTINCT cast_info.role_id) >= 2
)
SELECT
    rt.title AS Recent_Title,
    rt.production_year AS Year,
    pt.actor_count AS Popularity,
    ar.name AS Actor_Name,
    ar.num_roles AS Role_Count
FROM
    RecentTitles rt
LEFT JOIN
    PopularTitles pt ON rt.title_id = pt.title_id
LEFT JOIN
    cast_info ci ON rt.title_id = ci.movie_id
LEFT JOIN
    ActorRoles ar ON ci.person_id = ar.person_id
WHERE
    pt.actor_count IS NOT NULL
ORDER BY
    rt.production_year DESC, pt.actor_count DESC, ar.num_roles DESC
LIMIT
    50;
