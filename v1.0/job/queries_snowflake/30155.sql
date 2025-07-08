
WITH movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(ml.linked_movie_id, 0),
        mh.level + 1
    FROM 
        title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = m.id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    ak.name AS actor_name,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    COUNT(DISTINCT cc.id) AS cast_count,
    SUM(CASE 
            WHEN COALESCE(ci.note, '') != '' THEN 1 
            ELSE 0 
        END) AS notes_count,
    MAX(mh.level) AS max_link_depth
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    title t ON mh.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL
    AND ak.name IS NOT NULL
GROUP BY 
    t.title, t.production_year, ak.name
HAVING 
    COUNT(DISTINCT ci.id) > 5
ORDER BY 
    t.production_year DESC, max_link_depth DESC;
