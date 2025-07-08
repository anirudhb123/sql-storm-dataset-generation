
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  
    UNION ALL
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM
        aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COALESCE(mc.id, 0) AS company_id,
        COALESCE(ca.person_id, 0) AS actor_id,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        RANK() OVER (PARTITION BY mh.movie_id ORDER BY ca.nr_order) AS actor_rank
    FROM
        MovieHierarchy mh
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id AND mc.note IS NOT NULL
    LEFT JOIN cast_info ca ON mh.movie_id = ca.movie_id
    LEFT JOIN aka_name a ON ca.person_id = a.person_id
    WHERE
        mh.production_year > 2000  
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.level,
    md.company_id,
    LISTAGG(DISTINCT md.actor_name, ', ') WITHIN GROUP (ORDER BY md.actor_name) AS actors,
    COUNT(DISTINCT md.actor_id) AS actor_count,
    CASE
        WHEN COUNT(md.actor_id) > 3 THEN 'Ensemble Cast'
        WHEN COUNT(md.actor_id) = 0 THEN 'No Cast'
        ELSE 'Small Cast'
    END AS cast_size_label
FROM
    MovieDetails md
GROUP BY
    md.movie_id, md.title, md.production_year, md.level, md.company_id
HAVING
    COUNT(md.actor_id) > 0  
ORDER BY
    md.production_year DESC,
    md.level,
    actor_count DESC;
