
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title AS m
    WHERE
        m.production_year >= 2000 

    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link AS ml
    INNER JOIN
        title AS mt ON ml.linked_movie_id = mt.id
    INNER JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    LISTAGG(DISTINCT mh.title, '; ') WITHIN GROUP (ORDER BY mh.title) AS movie_titles,
    AVG(mh.production_year) AS avg_production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS actor_rank
FROM
    aka_name AS ak
JOIN
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN
    movie_hierarchy AS mh ON ci.movie_id = mh.movie_id
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND EXISTS (
        SELECT 1
        FROM role_type AS rt
        WHERE rt.id = ci.role_id
        AND rt.role IN ('Actor', 'Actress')
    )
GROUP BY
    ak.name, ak.person_id
HAVING
    COUNT(DISTINCT mh.movie_id) > 5 
ORDER BY
    total_movies DESC
LIMIT 10;
