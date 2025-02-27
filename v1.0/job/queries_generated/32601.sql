WITH RECURSIVE movie_hierarchy AS (
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
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.movie_id = m.id
    WHERE
        mh.level < 5   -- Limit the hierarchy to 5 levels deep
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS num_casts,
    COUNT(DISTINCT e.id) AS num_episodes,
    MAX(mh.level) AS level_in_hierarchy,
    CASE 
        WHEN COUNT(DISTINCT e.id) > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_episodes
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN
    title e ON cc.subject_id = e.id
LEFT JOIN
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE
    a.name IS NOT NULL
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY
    a.name, t.title, t.production_year
HAVING
    COUNT(DISTINCT c.id) > 1
ORDER BY
    t.production_year DESC, num_casts DESC;
