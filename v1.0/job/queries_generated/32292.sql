WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_id,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.movie_id AS parent_id,
        m.depth + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy m ON t.episode_of_id = m.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    COUNT(DISTINCT CASE WHEN c.person_role_id IS NOT NULL THEN c.person_id END) AS actor_count,
    AVG(COALESCE(m.production_year, 0)) AS avg_production_year,
    STRING_AGG(DISTINCT co.name, '; ') AS production_companies,
    MAX(mh.depth) AS max_episode_depth,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = m.movie_id) AS total_cast
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info c ON c.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL 
    AND (m.production_year BETWEEN 2000 AND 2023 OR m.production_year IS NULL)
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT m.movie_id) > 5
ORDER BY 
    movie_count DESC;
