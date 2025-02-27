WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        t.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        title t ON mc.linked_movie_id = t.id
    JOIN 
        aka_title m ON t.id = m.movie_id
    WHERE 
        m.production_year > 2000
)

SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS cast_count,
    CASE 
        WHEN mh.level = 1 THEN 'Direct'
        ELSE 'Indirect'
    END AS relationship_type
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    p.name IS NOT NULL
    AND mh.production_year IS NOT NULL
    AND (kw.keyword IS NULL OR kw.keyword <> 'Horror')
GROUP BY 
    p.first_name, p.last_name, mh.title, mh.production_year, mh.level
ORDER BY 
    actor_name, mh.production_year DESC;
