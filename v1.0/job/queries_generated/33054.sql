WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(255))
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    m.title AS movie_title,
    mh.level AS movie_level,
    mh.path AS movie_path,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mr.rating) AS average_rating
FROM 
    actor a
JOIN 
    cast_info ci ON a.id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_rating mr ON m.id = mr.movie_id
JOIN 
    aka_name ak ON a.id = ak.person_id
WHERE 
    m.production_year >= 2000
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
         OR m.production_year >= 2010)
    AND ak.name IS NOT NULL
GROUP BY 
    a.id, ak.name, m.title, mh.level, mh.path
ORDER BY 
    average_rating DESC, keyword_count DESC;
