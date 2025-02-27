WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY mc.note) AS median_cast_note_length,
    SUM(CASE WHEN cp.kind IS NULL THEN 1 ELSE 0 END) AS null_companies,
    MAX(CASE WHEN cp.kind IS NOT NULL THEN cp.kind ELSE 'No Company' END) AS company_name,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS aggregated_keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    comp_cast_type cp ON ci.person_role_id = cp.id
JOIN 
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
WHERE 
    mt.production_year > 2000
GROUP BY 
    a.name, mt.title, mt.production_year
ORDER BY 
    total_keywords DESC;
