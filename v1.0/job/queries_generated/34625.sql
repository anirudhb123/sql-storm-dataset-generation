WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1 AS depth
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.depth < 3
),
MovieActorInfo AS (
    SELECT
        ca.movie_id,
        ak.name AS actor_name,
        COUNT(ca.person_id) AS appearance_count,
        SUM(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM
        cast_info ca
    JOIN
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY
        ca.movie_id, ak.name
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        COALESCE(ma.appearance_count, 0) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY mh.depth, COALESCE(ma.appearance_count, 0) DESC) AS movie_rank
    FROM
        MovieHierarchy mh
    LEFT JOIN
        MovieActorInfo ma ON mh.movie_id = ma.movie_id
)

SELECT
    rm.movie_id,
    rm.movie_title,
    rm.actor_count,
    rm.movie_rank,
    STRING_AGG(DISTINCT ak.name, ', ') AS co_stars
FROM
    RankedMovies rm
LEFT JOIN
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY
    rm.movie_id, rm.movie_title, rm.actor_count, rm.movie_rank
HAVING
    rm.actor_count > 0
ORDER BY
    rm.movie_rank, rm.actor_count DESC;
