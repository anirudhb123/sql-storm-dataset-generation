WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY[mt.id] AS lineage
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL  -- Start with root movies (not episodes)
    
    UNION ALL

    SELECT
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.lineage || e.id
    FROM
        aka_title e
    JOIN
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),

MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(cc.id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COALESCE(ARRAY_AGG(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), '{}') AS keywords
    FROM
        MovieHierarchy mh
    LEFT JOIN
        cast_info cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        aka_name ak ON cc.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY
        mh.movie_id, mh.movie_title, mh.production_year
),

RatedMovies AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.total_cast_members,
        md.cast_names,
        md.keywords,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_cast_members DESC) AS rank_by_cast_size
    FROM
        MovieDetails md
)

SELECT
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.total_cast_members,
    rm.cast_names,
    rm.keywords,
    CASE
        WHEN rm.rank_by_cast_size <= 3 THEN 'Top 3 Casts'
        WHEN rm.rank_by_cast_size <= 10 THEN 'Top 10 Casts'
        ELSE 'Other'
    END AS category
FROM
    RatedMovies rm
WHERE
    rm.production_year >= 2000
    AND rm.total_cast_members > 5
ORDER BY
    rm.production_year DESC,
    rm.total_cast_members DESC;
