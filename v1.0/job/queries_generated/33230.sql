WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level,
        CAST(t.title AS VARCHAR(255)) AS hierarchy
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.hierarchy || ' -> ' || mt.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(*) OVER (PARTITION BY a.person_id) AS total_movies,
    MAX(CASE WHEN c.role_id IS NOT NULL THEN 'Starring' ELSE 'Unknown' END) AS role_status,
    mh.hierarchy AS movie_hierarchy,
    NULLIF(a.name_pcode_nf, '') AS name_code_nf
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND (c.note IS NULL OR c.note <> 'Cameo')
GROUP BY 
    a.name, t.title, t.production_year, mh.hierarchy
ORDER BY 
    total_movies DESC, t.production_year DESC
LIMIT 50;
