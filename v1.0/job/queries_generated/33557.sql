WITH RECURSIVE movie_chain AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS chain_level
    FROM
        movie_link ml
    WHERE
        ml.movie_id IS NOT NULL

    UNION ALL

    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        mc.chain_level + 1
    FROM
        movie_link ml
    JOIN
        movie_chain mc ON ml.movie_id = mc.linked_movie_id
)
SELECT
    ak.name AS actor_name,
    COALESCE(mt.production_year, 0) AS production_year,
    t.title AS movie_title,
    COUNT(DISTINCT mc.linked_movie_id) AS linked_movies_count,
    STRING_AGG(DISTINCT NULLIF(kw.keyword, ''), ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS rn
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')   
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    movie_chain mc ON t.id = mc.movie_id
LEFT JOIN
    aka_title mt ON t.id = mt.movie_id AND mt.production_year IS NOT NULL
WHERE
    ak.name IS NOT NULL AND ak.name != ''
    AND (t.production_year > 2000 OR ak.name LIKE '%Smith%')
    AND (ci.note IS NULL OR ci.note != 'Cameo')
GROUP BY
    ak.id, mt.production_year, t.title
HAVING
    COUNT(DISTINCT mc.linked_movie_id) > 2
ORDER BY
    actor_name, production_year DESC;
