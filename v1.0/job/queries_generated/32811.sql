WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.depth < 5
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS character_names,
    wt.kind AS work_type,
    COALESCE(COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.note IS NOT NULL), 0) AS cast_count,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS genre,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(m.production_year) OVER (PARTITION BY mh.depth) AS avg_year_at_depth,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Year: ' || mh.production_year::text
    END AS production_year_display
FROM
    MovieHierarchy mh
LEFT JOIN
    complete_cast cc ON cc.movie_id = mh.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN
    char_name cn ON cn.id = ci.person_role_id
LEFT JOIN
    kind_type wt ON wt.id = (SELECT kind_id FROM aka_title WHERE id = mh.movie_id)
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN
    movie_info mi ON mi.movie_id = mh.movie_id
GROUP BY
    mh.movie_id,
    mh.title,
    mh.production_year,
    wt.kind
ORDER BY
    avg_year_at_depth DESC,
    mh.title;
