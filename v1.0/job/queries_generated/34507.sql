WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT
        mc.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mh.depth < 3
)

SELECT 
    a.name AS actor_name,
    c.movie_id,
    t.title,
    t.production_year,
    COALESCE(SUM(CASE WHEN i.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    mh.depth AS movie_depth
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    aka_title t ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL 
    AND t.title IS NOT NULL
GROUP BY 
    a.id, c.movie_id, t.title, t.production_year, mh.depth
ORDER BY 
    actor_name, movie_depth DESC;
