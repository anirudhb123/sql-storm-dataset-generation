
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS movie_title,
        (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id) AS production_year,
        depth + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    AVG(CAST(mo.info AS FLOAT)) AS avg_movie_rating,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS ranking
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN
    movie_info mo ON at.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    ak.name IS NOT NULL
    AND ak.name != ''
    AND at.production_year > 2000
    AND (at.note IS NULL OR at.note NOT LIKE '%Not Released%')
GROUP BY
    ak.name, at.title, at.production_year
HAVING
    COUNT(DISTINCT at.id) >= 2
ORDER BY
    ak.name, at.production_year DESC;
