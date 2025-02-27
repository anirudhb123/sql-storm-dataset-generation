WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM
        aka_title t
    WHERE
        t.production_year > 2000

    UNION ALL

    SELECT
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        aka_title t ON m.linked_movie_id = t.id
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS movies_count,
    SUM(CASE 
            WHEN m.production_year = 2023 THEN 1
            ELSE 0 
        END) AS movies_2023,
    ARRAY_AGG(DISTINCT m.title) AS titles,
    AVG(mh.level) AS avg_recommended_level,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND m.production_year IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT m.movie_id) > 5
ORDER BY 
    movies_count DESC
LIMIT 10;
