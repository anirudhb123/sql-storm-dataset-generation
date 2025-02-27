
WITH RankedTitles AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        aka_title at
    JOIN
        movie_companies mc ON at.movie_id = mc.movie_id
    GROUP BY
        at.id, at.title, at.production_year
),
TopRatedTitles AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.company_count
    FROM
        RankedTitles rt
    JOIN
        movie_info mi ON rt.title_id = mi.movie_id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND CAST(mi.info AS numeric) > 8.0
),
ActorDetails AS (
    SELECT
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ci.nr_order AS role_order
    FROM
        cast_info ci
    JOIN
        aka_name ka ON ci.person_id = ka.person_id
    JOIN
        aka_title at ON ci.movie_id = at.movie_id
)
SELECT
    t.title,
    t.production_year,
    COUNT(DISTINCT ad.actor_name) AS actor_count,
    STRING_AGG(DISTINCT ad.actor_name, ', ') AS actor_names,
    t.company_count
FROM
    TopRatedTitles t
JOIN
    ActorDetails ad ON t.title = ad.movie_title
GROUP BY
    t.title, t.production_year, t.company_count
ORDER BY
    t.production_year DESC,
    actor_count DESC
LIMIT 10;
