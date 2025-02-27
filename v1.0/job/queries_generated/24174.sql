WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.episode_of_id,
        1 AS hierarchy_level,
        mt.note
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
        mt.episode_of_id,
        mh.hierarchy_level + 1,
        mt.note
    FROM
        aka_title mt
    JOIN
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CriticalMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.hierarchy_level,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        MovieHierarchy mh
    LEFT JOIN
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        mh.production_year >= 2000
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.hierarchy_level
    HAVING
        COUNT(ci.id) > 5
),
MovieDetails AS (
    SELECT 
        cm.movie_id,
        cm.title,
        cm.production_year,
        cm.hierarchy_level,
        cm.cast_count,
        cm.actor_names,
        ROW_NUMBER() OVER (PARTITION BY cm.hierarchy_level ORDER BY cm.production_year DESC) AS rank_in_level
    FROM 
        CriticalMovies cm
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.hierarchy_level,
    md.cast_count,
    md.actor_names,
    COALESCE(mk.keyword, 'No keyword') AS movie_keyword
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
WHERE
    md.rank_in_level <= 5
ORDER BY
    md.hierarchy_level,
    md.production_year DESC,
    md.movie_id;
