WITH RECURSIVE movie_series AS (
    SELECT t.id AS movie_id, t.title, t.season_nr, t.episode_nr, 1 AS depth
    FROM aka_title t
    WHERE t.episode_of_id IS NULL

    UNION ALL

    SELECT t.id AS movie_id, t.title, t.season_nr, t.episode_nr, ms.depth + 1
    FROM aka_title t
    JOIN movie_series ms ON t.episode_of_id = ms.movie_id
),

actor_movie_info AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE a.name IS NOT NULL AND t.production_year IS NOT NULL
),

keyword_stats AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS distinct_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

complex_conditions AS (
    SELECT
        c.movie_id,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS total_cast,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned
    FROM cast_info c
    JOIN aka_title t ON c.movie_id = t.id
    GROUP BY c.movie_id
)

SELECT
    a.actor_name,
    a.movie_title,
    a.production_year,
    ms.season_nr,
    ms.episode_nr,
    COALESCE(ks.distinct_keywords, 0) AS keyword_count,
    cc.total_cast,
    cc.roles_assigned,
    CASE
        WHEN cc.total_cast = 0 THEN NULL
        ELSE (cc.roles_assigned * 1.0 / cc.total_cast)
    END AS role_assignment_ratio
FROM actor_movie_info a
LEFT JOIN movie_series ms ON ms.movie_id = a.movie_id
LEFT JOIN keyword_stats ks ON ks.movie_id = a.movie_id
LEFT JOIN complex_conditions cc ON cc.movie_id = a.movie_title
WHERE a.rn = 1
AND (a.production_year > 2000 OR ms.season_nr IS NOT NULL)
ORDER BY a.production_year DESC, a.actor_name;

