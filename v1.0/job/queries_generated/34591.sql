WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        ARRAY[m.id] AS movie_path,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        mh.movie_path || m.id,
        mh.depth + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mh ON mh.id = ml.linked_movie_id
)
SELECT
    m.title AS movie_title,
    m.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS cast_names,
    COUNT(DISTINCT kc.id) AS keyword_count,
    COALESCE(NULLIF(mi.info, ''), 'No additional info') AS info,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ak.name) DESC) AS cast_rank
FROM
    movie_hierarchy mh
JOIN
    aka_title m ON m.id = mh.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = m.id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN
    keyword kc ON kc.id = mk.keyword_id
LEFT JOIN
    movie_info mi ON mi.movie_id = m.id
WHERE
    m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    AND (m.production_year IS NOT NULL OR m.production_year < 2023)
GROUP BY
    m.id, m.title, m.production_year, mi.info
ORDER BY
    m.production_year DESC, cast_rank
LIMIT 100;
