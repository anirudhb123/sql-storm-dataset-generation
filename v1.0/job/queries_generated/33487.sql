WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT ci.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(CASE WHEN ai.info IS NOT NULL THEN LENGTH(ai.info) ELSE 0 END) AS avg_info_length,
    COUNT(DISTINCT ki.keyword) AS keyword_count,
    COALESCE(NULLIF(SUM(mo.id), 0), 'No Movies') AS movie_impact_metric,
    CASE 
        WHEN mh.production_year > 2000 THEN 'Modern'
        WHEN mh.production_year BETWEEN 1980 AND 2000 THEN 'Classic'
        ELSE 'Vintage' 
    END AS era
FROM
    movie_hierarchy mh
LEFT JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN
    movie_info ai ON mh.movie_id = ai.movie_id AND ai.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
LEFT JOIN
    movie_link mo ON mh.movie_id = mo.movie_id 
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY
    mh.production_year DESC, mh.depth ASC;
