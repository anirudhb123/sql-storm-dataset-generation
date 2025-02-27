WITH RECURSIVE TitleHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Start with root titles

    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title,
        e.production_year,
        th.level + 1
    FROM
        aka_title e
    INNER JOIN TitleHierarchy th ON th.movie_id = e.episode_of_id  -- Join with episodes
),
ActorRoles AS (
    SELECT
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.id
    WHERE
        ak.name IS NOT NULL
        AND ak.name <> ''  -- Filter out NULL or empty names
    GROUP BY
        a.id, ak.name
),
TopActors AS (
    SELECT
        actor_id, actor_name, movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM
        ActorRoles
),
MovieInfo AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        coalesce(GROUP_CONCAT(kw.keyword), '') AS keywords
    FROM
        aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY
        mt.id, mt.title, mt.production_year
)
SELECT
    th.title AS episode_title,
    th.production_year,
    ta.actor_name,
    ta.movie_count,
    mi.keywords
FROM
    TitleHierarchy th
JOIN
    TopActors ta ON th.movie_id = ta.actor_id
JOIN
    MovieInfo mi ON th.movie_id = mi.movie_id
WHERE
    th.level > 0  -- Select only episodes
    AND ta.actor_rank <= 10  -- Filter top 10 actors
ORDER BY
    th.production_year DESC, ta.movie_count DESC;

