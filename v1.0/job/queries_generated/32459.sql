WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        mt.episode_of_id
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1,
        mt.episode_of_id
    FROM
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
ActorInfo AS (
    SELECT
        ak.name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(COALESCE(m.production_year, 0)) AS average_production_year
    FROM
        aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    LEFT JOIN aka_title m ON c.movie_id = m.id
    GROUP BY
        ak.name
),
RankedActors AS (
    SELECT
        name,
        total_movies,
        average_production_year,
        RANK() OVER (ORDER BY total_movies DESC) AS actor_rank
    FROM
        ActorInfo
)
SELECT
    mh.title,
    mh.production_year,
    ra.name AS actor_name,
    ra.total_movies,
    ra.average_production_year,
    CASE 
        WHEN ra.average_production_year < 2000 THEN 'Classic'
        WHEN ra.average_production_year >= 2000 AND ra.average_production_year < 2010 THEN 'Contemporary'
        ELSE 'Modern'
    END AS film_category
FROM
    MovieHierarchy mh
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN RankedActors ra ON ci.person_id = ra.actor_id
WHERE
    mh.depth <= 2
    AND (ra.total_movies IS NOT NULL OR ra.total_movies > 10)
ORDER BY
    mh.production_year DESC,
    ra.total_movies DESC;
