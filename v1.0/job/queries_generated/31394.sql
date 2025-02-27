WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(ml.linked_movie_id, -1) AS linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    INNER JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    INNER JOIN 
        title t ON ml.linked_movie_id = t.id
)

SELECT 
    m.title AS linked_title,
    array_agg(DISTINCT a.name) AS actor_names,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN ti.info IS NOT NULL THEN LENGTH(ti.info) ELSE 0 END) AS avg_info_length,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    RANK() OVER (ORDER BY COUNT(DISTINCT a.id) DESC) AS rank_by_actors
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_info ti ON m.movie_id = ti.movie_id
LEFT JOIN 
    movie_keyword mw ON m.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
WHERE 
    m.level <= 2 AND 
    (m.linked_movie_id <> -1 OR m.linked_movie_id IS NULL)
GROUP BY 
    m.title
ORDER BY 
    rank_by_actors;
