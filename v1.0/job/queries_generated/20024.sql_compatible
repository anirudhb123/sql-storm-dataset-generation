
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT MIN(id) FROM kind_type WHERE kind = 'movie')
        AND mt.production_year >= 2000
        
    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 5
)

SELECT
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c.role_id) AS total_roles,
    AVG(EXTRACT(YEAR FROM DATE '2024-10-01') - mh.production_year) AS avg_age_of_movies,
    STRING_AGG(DISTINCT ik.keyword || ' (' || ik.id || ')', ', ') AS movie_keywords,
    CASE 
        WHEN COUNT(DISTINCT c.role_id) = 0 THEN 'No roles'
        ELSE 'Has roles'
    END AS role_presence,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.role_id) DESC) AS rank
FROM
    movie_hierarchy mh
JOIN
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN
    cast_info c ON cc.subject_id = c.person_id
JOIN
    aka_name ak ON c.person_id = ak.person_id
JOIN
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN
    keyword ik ON mk.keyword_id = ik.id
LEFT JOIN
    movie_info mi ON mh.movie_id = mi.movie_id 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Description')
WHERE
    ak.name IS NOT NULL
GROUP BY
    ak.name, mh.title, mh.production_year
HAVING
    AVG(EXTRACT(YEAR FROM DATE '2024-10-01') - mh.production_year) > 15
ORDER BY
    mh.production_year DESC, total_roles DESC
LIMIT 100;
