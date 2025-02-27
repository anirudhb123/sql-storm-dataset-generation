WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(m2.title, 'N/A') AS parent_title,
        COALESCE(m2.production_year, 0) AS parent_year,
        0 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN title m2 ON ml.linked_movie_id = m2.id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        t.movie_title,
        t.production_year,
        level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy t ON ml.movie_id = t.movie_id
)

SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    hk.keyword AS keywords,
    ak.name AS actor_name,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY ak.name) AS actor_rank,
    COUNT(CASE WHEN ak.gender = 'F' THEN 1 END) OVER (PARTITION BY m.id) AS female_actors_count,
    lm.link_type AS link_description,
    CASE 
        WHEN mh.level IS NULL THEN 'Independent'
        ELSE 'Linked'
    END AS hierarchy_type
FROM 
    title m
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword hk ON mk.keyword_id = hk.id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_link ml ON m.id = ml.movie_id
LEFT JOIN 
    link_type lm ON ml.link_type_id = lm.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND (m.production_year > 2010 OR m.production_year < 2000)
ORDER BY 
    m.production_year DESC, 
    actor_rank
FETCH FIRST 100 ROWS ONLY;

