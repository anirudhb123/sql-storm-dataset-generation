WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Get root movies (non-episodes)
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    mh.production_year AS year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mi.movie_rating) AS avg_rating,
    COUNT(DISTINCT mw.keyword_id) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mh.production_year DESC) AS ranking
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') -- Correlated subquery
LEFT JOIN 
    movie_keyword mw ON m.id = mw.movie_id
JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
    AND (m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film') OR m.kind_id IS NULL)
GROUP BY 
    a.name, m.title, mh.production_year
HAVING 
    COUNT(DISTINCT mw.keyword_id) > 3
ORDER BY 
    ranking;
