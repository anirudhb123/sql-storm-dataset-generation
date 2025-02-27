WITH RecursiveActorMovies AS (
    SELECT
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM
        cast_info c
    JOIN
        aka_title t ON c.movie_id = t.id
    WHERE
        c.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
),
ActorsWithMultipleMovies AS (
    SELECT
        person_id,
        COUNT(*) AS movie_count
    FROM
        RecursiveActorMovies
    WHERE
        recent_movie_rank <= 5
    GROUP BY
        person_id
    HAVING
        COUNT(*) > 3
),
ActorsDetails AS (
    SELECT
        a.id AS actor_id,
        a.name,
        am.movie_count,
        COALESCE(MAX(m.info), 'No Info') AS recent_info
    FROM
        aka_name a
    INNER JOIN
        ActorsWithMultipleMovies am ON a.person_id = am.person_id
    LEFT JOIN
        person_info m ON a.person_id = m.person_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
    GROUP BY
        a.id, am.movie_count
)
SELECT
    ad.actor_id,
    ad.name,
    ad.movie_count,
    COALESCE(ad.recent_info, 'No biography available') AS biography,
    CASE
        WHEN ad.movie_count IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS status,
    p.id AS movie_id,
    p.title AS recent_movie
FROM
    ActorsDetails ad
LEFT JOIN (
    SELECT
        c.person_id,
        t.id,
        t.title
    FROM
        cast_info c
    JOIN
        aka_title t ON c.movie_id = t.id
    WHERE
        c.nr_order = 1
) p ON ad.actor_id = p.person_id
ORDER BY
    ad.movie_count DESC,
    ad.name ASC
LIMIT 10;

-- Extra handling for NULL cases
WITH NullHandling AS (
    SELECT
        t.id AS title_id,
        t.title,
        COALESCE(t.production_year, 0) AS production_year,
        COUNT(mk.keyword) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    WHERE
        t.production_year IS NULL OR t.production_year < 2000
    GROUP BY
        t.id
    HAVING
        COUNT(mk.keyword) > 2
)
SELECT
    th.title_id,
    th.title,
    th.production_year,
    CASE
        WHEN th.production_year = 0 THEN 'Unknown Year'
        ELSE th.production_year::text
    END AS showcase_year
FROM
    NullHandling th
ORDER BY
    th.keyword_count DESC
LIMIT 5;
