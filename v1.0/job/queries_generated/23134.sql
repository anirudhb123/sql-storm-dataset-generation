WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    WHERE
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN aka_title m2 ON m2.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON mh.movie_id = m.id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_linked_movies,
    STRING_AGG(DISTINCT mh.path) AS linked_movie_paths
FROM
    aka_name ak
JOIN
    cast_info ci ON ci.person_id = ak.person_id
JOIN
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
LEFT JOIN
    (SELECT
         m.id,
         COALESCE(SUM(mi.info_length), 0) AS total_info_length
     FROM
         aka_title m
     LEFT JOIN
         (SELECT
              movie_id,
              LENGTH(info) AS info_length
          FROM
              movie_info
          WHERE
              note IS NOT NULL
         ) mi ON mi.movie_id = m.id
     GROUP BY
         m.id
    ) AS info_summary ON info_summary.id = mh.movie_id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name
HAVING
    COUNT(DISTINCT mh.movie_id) > 1
    OR MAX(COALESCE(info_summary.total_info_length, 0)) > 50
ORDER BY
    total_linked_movies DESC,
    actor_name
LIMIT 10;
