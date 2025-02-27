WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM
        aka_title AS m
    WHERE
        m.production_year >= 2000
  
    UNION ALL
  
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link AS ml
    JOIN
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.depth < 3
),
AggregatedCast AS (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
        COUNT(DISTINCT p.id) AS cast_count
    FROM
        cast_info AS c
    JOIN
        aka_name AS p ON c.person_id = p.person_id
    GROUP BY
        c.movie_id
),
KeywordAggregation AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword AS mk
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ac.cast_names, 'No Cast') AS cast_names,
    COALESCE(ac.cast_count, 0) AS cast_count,
    COALESCE(ka.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE mh.production_year::text 
    END AS year_info
FROM
    MovieHierarchy AS mh
LEFT JOIN
    AggregatedCast AS ac ON mh.movie_id = ac.movie_id
LEFT JOIN
    KeywordAggregation AS ka ON mh.movie_id = ka.movie_id
WHERE
    mh.depth < 3
ORDER BY
    mh.production_year DESC,
    mh.title;
