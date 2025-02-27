WITH RECURSIVE movie_hierarchy AS (
    -- Base case: select all movies without parents
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS level
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    -- Recursive case: find child movies linked to their parents
    SELECT
        l.linked_movie_id AS movie_id,
        m.title AS movie_title,
        mh.level + 1
    FROM
        movie_link l
    JOIN
        movie_hierarchy mh ON l.movie_id = mh.movie_id
    JOIN
        aka_title m ON l.linked_movie_id = m.id
)

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    MAX(CASE 
            WHEN r.role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS has_role,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mi.info::float) AS average_rating
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    title t ON ci.movie_id = t.id 
LEFT JOIN
    role_type r ON ci.role_id = r.id
LEFT JOIN
    movie_hierarchy mh ON t.id = mh.movie_id
WHERE
    t.production_year > 2000
    AND (c.country_code IS NOT NULL OR c.country_code <> '')
GROUP BY
    a.name, t.title
HAVING
    COUNT(DISTINCT k.id) > 3
ORDER BY
    average_rating DESC;
