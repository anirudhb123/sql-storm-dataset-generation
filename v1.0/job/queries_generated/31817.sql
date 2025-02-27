WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year = 2023
        
    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        mh.level + 1 AS level
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.movie_id = m.id
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.linked_movie_id
)
, movie_info_expanded AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No info available') AS info,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_additional_info,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.title) AS info_row_num
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY
        m.id, mi.info
)
SELECT
    mh.movie_id,
    mh.movie_title,
    m.info,
    mh.level,
    CASE
        WHEN m.production_companies > 3 THEN 'Major Production'
        WHEN m.production_companies BETWEEN 1 AND 3 THEN 'Independent'
        ELSE 'Unknown'
    END AS production_type,
    MAX(m.info_row_num) OVER (PARTITION BY mh.movie_id) AS max_info_row
FROM
    movie_hierarchy mh
LEFT JOIN
    movie_info_expanded m ON mh.movie_id = m.movie_id
WHERE
    mh.level <= 2
ORDER BY
    mh.level, mh.movie_title, production_type DESC;
