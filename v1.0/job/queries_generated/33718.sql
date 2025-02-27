WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(255))
    FROM
        MovieHierarchy mh
    JOIN
        aka_title m ON mh.movie_id = m.episode_of_id
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'episode')
)
SELECT
    ak.name AS actor,
    ak.md5sum AS actor_md5,
    mt.title AS movie_title,
    mt.production_year,
    ch.name AS character_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    MAX(p.info) AS director_info,
    ROW_NUMBER() OVER (PARTITION BY mt.title ORDER BY mt.production_year DESC) AS row_num
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    char_name ch ON ch.id = ci.role_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN
    person_info p ON p.person_id = ci.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE
    mt.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND (ch.name IS NULL OR LENGTH(ch.name) > 0)
GROUP BY
    ak.name,
    ak.md5sum,
    mt.title,
    mt.production_year,
    ch.name
HAVING
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY
    mt.production_year DESC,
    row_num
LIMIT 100;
