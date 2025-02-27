WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
        
    UNION ALL
    
    SELECT 
        mm.id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        aka_title mm
    JOIN 
        movie_link ml ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    coalesce(a.name, 'Unknown Actor') AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    SUM(mi.info IS NOT NULL::integer) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS actor_rank
FROM 
    movie_hierarchy m
JOIN 
    complete_cast cc ON cc.movie_id = m.movie_id
JOIN 
    cast_info c ON c.movie_id = m.id AND c.person_id = cc.subject_id
JOIN 
    aka_name a ON a.person_id = c.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id = 1
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    a.person_id, m.title, m.production_year
HAVING 
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) > 1
ORDER BY 
    actor_rank ASC,
    m.production_year DESC;
