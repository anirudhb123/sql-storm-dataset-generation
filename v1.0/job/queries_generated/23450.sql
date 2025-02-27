WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000

    UNION ALL

    SELECT
        l.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        l.movie_id AS parent_movie_id,
        mh.level + 1
    FROM
        movie_link l
    JOIN aka_title mt ON l.linked_movie_id = mt.id
    JOIN MovieHierarchy mh ON l.movie_id = mh.movie_id
)
, RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS movie_rank,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS total_movies
    FROM
        MovieHierarchy mh
    WHERE
        mh.level = 1 OR mh.level IS NULL
)
SELECT
    rm.title,
    rm.production_year,
    rm.movie_rank,
    rm.total_movies,
    COALESCE(Aka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT cc.person_id) AS distinct_cast_members,
    array_agg(DISTINCT kw.keyword) AS keywords
FROM
    RankedMovies rm
LEFT JOIN cast_info cc ON cc.movie_id = rm.movie_id
LEFT JOIN aka_name Aka ON Aka.person_id = cc.person_id
LEFT JOIN movie_keyword mk ON mk.movie_id = rm.movie_id
LEFT JOIN keyword kw ON kw.id = mk.keyword_id
WHERE
    rm.production_year <= 2023
GROUP BY
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.movie_rank,
    rm.total_movies,
    Aka.name
HAVING
    COUNT(DISTINCT cc.person_id) > 2 OR rm.total_movies > 10
ORDER BY
    rm.production_year DESC,
    rm.movie_rank
LIMIT 50;
