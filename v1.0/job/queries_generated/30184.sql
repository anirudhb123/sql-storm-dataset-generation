WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(ci.id) AS role_count,
    ARRAY_AGG(DISTINCT ct.kind) AS cast_types,
    MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') THEN pi.info END) AS birth_date,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS rn
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN
    comp_cast_type ct ON ci.person_role_id = ct.id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN
    person_info pi ON ak.person_id = pi.person_id
WHERE
    mt.production_year >= 2000
    AND ak.name IS NOT NULL
    AND mt.title NOT LIKE '%Untitled%'
GROUP BY
    ak.name,
    mt.title,
    mt.production_year
HAVING
    COUNT(ci.id) > 1
    AND MAX(mt.production_year) >= (SELECT AVG(production_year) FROM aka_title)
ORDER BY
    actor_name,
    movie_title;
