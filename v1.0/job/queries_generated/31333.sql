WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select all movies
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS episode_of_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    -- Recursive case: join movies to their episodes
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
        mh.level + 1
    FROM
        aka_title mt
        JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    t.title,
    t.production_year,
    COALESCE(c.name, 'No Company') AS company_name,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id) AS total_cast,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_order,
    (SELECT COUNT(DISTINCT mk.keyword) FROM movie_keyword mk WHERE mk.movie_id = t.id) AS unique_keywords,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2020 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM
    movie_hierarchy mh
    JOIN cast_info ci ON mh.movie_id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    JOIN title t ON mh.movie_id = t.id
WHERE
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
    AND (t.production_year BETWEEN 1980 AND 2023 OR t.production_year IS NULL)
ORDER BY
    t.production_year DESC,
    actor_order;
