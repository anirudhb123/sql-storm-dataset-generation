WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        aka_title t ON m.linked_movie_id = t.id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),

AggregatedInfo AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        MIN(mi.info) AS first_info,
        MAX(mi.info) AS last_info
    FROM
        complete_cast cc
    JOIN
        aka_title at ON cc.movie_id = at.id
    JOIN
        cast_info c ON cc.subject_id = c.person_id
    JOIN
        person_info pi ON c.person_id = pi.person_id
    JOIN
        movie_info mi ON cc.movie_id = mi.movie_id
    LEFT JOIN
        aka_name a ON a.person_id = c.person_id
    GROUP BY
        m.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    ai.cast_count,
    ai.actors,
    ai.first_info,
    ai.last_info,
    COALESCE(ai.cast_count, 0) AS safe_cast_count
FROM
    MovieHierarchy mh
LEFT JOIN
    AggregatedInfo ai ON mh.movie_id = ai.movie_id
WHERE
    mh.level <= 2
ORDER BY
    mh.production_year DESC,
    ai.cast_count DESC NULLS LAST
LIMIT 100;
