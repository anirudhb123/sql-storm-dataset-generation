WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year > 2000

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cm.subject_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cm.subject_id) DESC) AS rn,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM
        MovieHierarchy mh
    LEFT JOIN
        complete_cast cm ON mh.movie_id = cm.movie_id
    LEFT JOIN
        cast_info cc ON cm.subject_id = cc.person_id
    LEFT JOIN
        aka_name a ON cc.person_id = a.person_id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    COALESCE(mi.info, 'No info available') AS movie_info,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
FROM
    RankedMovies rm
LEFT JOIN
    movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Synopsis'
    )
WHERE
    rm.rn <= 5
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;
