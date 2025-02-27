WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming '1' is for 'film'

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        aka_title mt
    JOIN
        movie_link ml ON mt.id = ml.linked_movie_id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

actor_movie AS (
    SELECT
        aki.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT akic.movie_id) OVER (PARTITION BY aki.person_id) AS total_movies,
        ROW_NUMBER() OVER (PARTITION BY aki.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM
        cast_info aki
    JOIN
        aka_name ak ON ak.person_id = aki.person_id
    JOIN
        aka_title at ON at.id = aki.movie_id
    LEFT JOIN
        complete_cast acc ON acc.movie_id = aki.movie_id
    LEFT JOIN
        movie_info mi ON mi.movie_id = aki.movie_id
    WHERE
        at.production_year IS NOT NULL
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
)

SELECT
    DISTINCT mh.movie_id,
    mh.title,
    mh.production_year,
    am.actor_name,
    am.total_movies,
    CASE WHEN am.movie_rank = 1 THEN 'Newest' ELSE 'Older' END AS movie_status
FROM
    movie_hierarchy mh
JOIN
    actor_movie am ON am.movie_title = mh.title
WHERE
    mh.depth <= 3
    AND am.total_movies > 5
ORDER BY
    mh.production_year DESC, am.actor_name;
This SQL query performs an elaborate performance benchmarking involving a recursive CTE to build a movie hierarchy, calculates the number of movies an actor has worked on using window functions, and includes complex filtering criteria. The joins leverage outer joins, aggregations, and correlated subqueries, showcasing the relationships between movies, actors, and their classifications.
