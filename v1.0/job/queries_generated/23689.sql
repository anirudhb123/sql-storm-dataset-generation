WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        COALESCE(NULLIF(mt.production_year, 0), NULL) AS effective_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        at.title,
        at.production_year,
        COALESCE(NULLIF(at.production_year, 0), NULL) AS effective_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.effective_year,
    COUNT(DISTINCT ci.person_role_id) OVER (PARTITION BY mt.id) AS role_count,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles,
    MAX(CASE 
        WHEN ci.note IS NOT NULL THEN ci.note 
        ELSE 'No special notes' 
    END) AS special_note,
    COUNT(DISTINCT mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS keyword_count
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023
    AND (mh.effective_year IS NULL OR mh.effective_year > 2000)
GROUP BY 
    ak.name, mt.title, mh.effective_year
HAVING 
    COUNT(DISTINCT ci.id) > 2 
ORDER BY 
    COUNT(DISTINCT mk.keyword) DESC, 
    mh.effective_year ASC, 
    ak.name ASC;
