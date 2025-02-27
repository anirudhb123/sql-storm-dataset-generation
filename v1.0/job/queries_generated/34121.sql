WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
),

CastDetails AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
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
),

MovieSummary AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(cd.actor_name, 'No Cast') AS actor_name,
        COALESCE(cd.role_name, 'Unknown Role') AS role_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        mh.level
    FROM
        MovieHierarchy mh
    LEFT JOIN
        CastDetails cd ON mh.movie_id = cd.movie_id
    LEFT JOIN
        MovieKeywords mk ON mh.movie_id = mk.movie_id
)

SELECT
    movie_title,
    production_year,
    actor_name,
    role_name,
    keywords,
    level
FROM
    MovieSummary
WHERE
    production_year >= 2000
    AND (keywords LIKE '%Action%' OR role_name <> 'Unknown Role')
ORDER BY
    production_year DESC,
    movie_title;
