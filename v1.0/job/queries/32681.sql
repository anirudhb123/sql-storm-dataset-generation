
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  
    UNION ALL
    SELECT
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM
        aka_title mt
    INNER JOIN
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_order
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    cd.actor_name,
    cd.role_name,
    mk.keywords,
    CASE 
        WHEN COUNT(cd.actor_name) > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_presence,
    MAX(cd.actor_order) AS total_actors
FROM
    MovieHierarchy mh
LEFT JOIN
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN
    MovieKeywords mk ON mh.movie_id = mk.movie_id
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.kind_id, cd.actor_name, cd.role_name, mk.keywords
ORDER BY
    mh.production_year DESC,
    mh.title ASC,
    total_actors DESC 
LIMIT 100;
