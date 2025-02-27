WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        m.title AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_list,
    COUNT(DISTINCT c.id) OVER(PARTITION BY ak.id) AS movies_count,
    CASE 
        WHEN COUNT(DISTINCT c.id) > 5 THEN 'Prolific Actor'
        ELSE 'Regular Actor'
    END AS actor_status,
    COALESCE(ci.note, 'No Note') AS role_note,
    NULLIF(CAST(mh.production_year AS text), '0') AS production_year_check
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    movie_keyword mk ON mk.movie_id = at.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = at.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = at.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    mh.level <= 3
GROUP BY 
    ak.id, mh.title, mh.production_year, ci.note
ORDER BY 
    total_keywords DESC, actor_name ASC;
