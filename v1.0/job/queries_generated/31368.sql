WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM
        aka_title mt
    JOIN
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
GenreCounts AS (
    SELECT
        k.keyword AS genre,
        COUNT(mk.movie_id) AS movie_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        k.keyword
),
TopGenres AS (
    SELECT
        genre,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS genre_rank
    FROM
        GenreCounts
    WHERE
        movie_count > 50
),
PersonRoles AS (
    SELECT
        ci.person_id,
        GROUP_CONCAT(DISTINCT rt.role) AS roles
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.person_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL), ARRAY[]::text[]) AS cast_names,
        COALESCE(ARRAY_AGG(DISTINCT p.roles) FILTER (WHERE p.roles IS NOT NULL), ARRAY[]::text[]) AS person_roles
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        PersonRoles p ON ci.person_id = p.person_id
    GROUP BY
        m.id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level AS episode_level,
    ARRAY_AGG(DISTINCT tg.genre) AS genres,
    md.cast_names,
    md.person_roles
FROM
    MovieHierarchy mh
LEFT JOIN
    MovieDetails md ON mh.movie_id = md.movie_id
LEFT JOIN
    TopGenres tg ON md.cast_names && ARRAY(SELECT keyword FROM keyword WHERE id IN (SELECT keyword_id FROM movie_keyword WHERE movie_id = mh.movie_id))
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY
    mh.production_year DESC,
    episode_level ASC;
