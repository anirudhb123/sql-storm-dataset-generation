WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mtl.linked_movie_id,
        1 AS level
    FROM
        title mt
    LEFT JOIN
        movie_link mtl ON mt.id = mtl.movie_id
    WHERE
        mt.production_year >= 2000  -- filter for recent movies
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mtl.linked_movie_id,
        mh.level + 1
    FROM
        title mt
    INNER JOIN
        movie_link mtl ON mt.id = mtl.linked_movie_id
    INNER JOIN
        movie_hierarchy mh ON mh.movie_id = mtl.movie_id
)
SELECT
    t.title AS original_title,
    t.production_year,
    COALESCE(ca.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mh.linked_movie_id) AS related_movies,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn,
    string_agg(DISTINCT k.keyword, ', ') AS keywords
FROM
    title t
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name ca ON ci.person_id = ca.person_id
LEFT JOIN
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE
    t.production_year BETWEEN 2000 AND 2023  -- recent years
    AND (k.keyword IS NOT NULL OR ci.note IS NULL)  -- filtering NULL keywords
GROUP BY
    t.id, t.title, t.production_year, ca.name
ORDER BY
    t.production_year DESC, related_movies DESC;
