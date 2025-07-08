
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        mh.level < 3
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN mp.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    AVG(mt.production_year) OVER (PARTITION BY ak.name) AS avg_production_year,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN
    movie_info mp ON mt.id = mp.movie_id AND mp.info_type_id IN (SELECT id FROM info_type WHERE info = 'note')
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name, mt.title, mt.production_year
HAVING
    COUNT(DISTINCT ci.id) > 2
ORDER BY
    avg_production_year DESC, 
    mt.production_year ASC;
