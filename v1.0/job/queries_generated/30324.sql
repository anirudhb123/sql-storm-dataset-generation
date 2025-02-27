WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieCast AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
),
Keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.title,
    mh.level,
    CAST(COALESCE(mc.actor_name, 'Unknown Actor') AS TEXT) AS actor,
    mc.role,
    COALESCE(kw.keyword_list, 'No Keywords') AS keywords,
    COUNT(mc.actor_name) OVER (PARTITION BY mh.movie_id) AS total_actors
FROM
    MovieHierarchy mh
LEFT JOIN
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN
    Keywords kw ON mh.movie_id = kw.movie_id
WHERE
    mh.level <= 2
ORDER BY
    mh.level, mh.title, mc.actor_rank;
