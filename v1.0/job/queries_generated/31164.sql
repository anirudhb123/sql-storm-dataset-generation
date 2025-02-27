WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT
    a.name AS actor,
    t.title AS movie_title,
    mh.level AS movie_level,
    COALESCE(COUNT(DISTINCT mi.info), 0) AS interesting_info_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT p.info, '; ') AS actor_info
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY
    a.name, t.title, mh.level
HAVING
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY
    movie_level, actor;
