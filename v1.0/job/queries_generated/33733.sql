WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM
        aka_title t
    JOIN
        movie_companies mc ON t.id = mc.movie_id
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title t ON ml.linked_movie_id = t.id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY
    mh.level DESC, mh.production_year DESC
LIMIT 10;

-- Performance Benchmarking Analysis
WITH Benchmark AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM
        MovieHierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        mh.production_year BETWEEN 2000 AND 2023
    GROUP BY
        mh.movie_id, mh.title, mh.production_year, mh.level
)

SELECT
    bm.movie_id,
    bm.title,
    bm.production_year,
    bm.level,
    bm.cast_count,
    bm.actor_names
FROM
    Benchmark bm
WHERE
    bm.rn <= 5
ORDER BY
    bm.cast_count DESC;
