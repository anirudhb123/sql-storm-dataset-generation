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

CastWithRoles AS (
    SELECT
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    COUNT(cwr.actor_name) AS actor_count,
    STRING_AGG(DISTINCT cwr.actor_name, ', ') AS cast,
    MAX(CASE WHEN cwr.role = 'Director' THEN cwr.actor_name END) AS director_name,
    SUM(CASE WHEN cwr.role = 'Director' THEN 1 ELSE 0 END) AS director_count
FROM
    MovieHierarchy mh
LEFT JOIN
    CastWithRoles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN
    MovieKeywords kw ON mh.movie_id = kw.movie_id
WHERE
    mh.production_year >= 2000
GROUP BY
    mh.movie_id, mh.title, mh.production_year
HAVING
    COUNT(cwr.actor_name) > 1
ORDER BY
    mh.production_year DESC,
    actor_count DESC;
