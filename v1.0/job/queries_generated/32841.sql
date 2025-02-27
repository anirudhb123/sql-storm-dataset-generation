WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        ARRAY[mt.id] AS path
    FROM
        aka_title mt
    WHERE 
        mt.production_year > 2000 -- Filter for recent movies

    UNION ALL

    SELECT
        lm.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        path || lm.linked_movie_id  -- Append linked movie ID to path
    FROM
        movie_link lm
    JOIN
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
    JOIN
        aka_title m ON lm.linked_movie_id = m.id
    WHERE 
        lm.linked_movie_id IS NOT NULL
),
TopMovies AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        aka_title a ON mk.movie_id = a.id
    WHERE
        a.production_year > 2000
    GROUP BY
        mk.movie_id
    ORDER BY
        keyword_count DESC
    LIMIT 10
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        c.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(td.keyword_count, 0) AS keyword_count,
    COALESCE(cd.cast_count, 0) AS cast_count,
    cd.cast_names,
    mh.level,
    mh.path
FROM
    MovieHierarchy mh
LEFT JOIN
    TopMovies td ON mh.movie_id = td.movie_id
LEFT JOIN
    CastDetails cd ON mh.movie_id = cd.movie_id
WHERE
    cd.cast_count > 5 OR mh.level < 3  -- Filter criteria based on cast count or hierarchy level
ORDER BY
    mh.production_year DESC, keyword_count DESC;

