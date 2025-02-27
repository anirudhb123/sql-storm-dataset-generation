WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS total_casts,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present,
    AVG(COALESCE(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END, 0)) AS avg_info_length,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ak.name) AS actor_rank
FROM
    movie_hierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info c ON cc.subject_id = c.person_id
JOIN
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN
    person_info pi ON c.person_id = pi.person_id
LEFT JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    mh.level = 0 
    AND ak.name IS NOT NULL
GROUP BY
    ak.name, mh.title, mh.production_year
HAVING
    COUNT(DISTINCT c.id) > 2
ORDER BY
    mh.production_year DESC, total_casts DESC;
