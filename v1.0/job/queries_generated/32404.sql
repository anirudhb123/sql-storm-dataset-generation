WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info AS ca
    WHERE 
        ca.role_id = (SELECT id FROM role_type WHERE role = 'Actor')
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info AS ca
    INNER JOIN 
        ActorHierarchy AS ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.role_id = (SELECT id FROM role_type WHERE role IN ('Supporting Actor', 'Actor'))  -- Supports recursive search for supporting actors
)

SELECT 
    ak.name AS actor_name,
    tk.title AS movie_title,
    tk.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mv.info_length) AS avg_info_length,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS not_null_note_count,
    STRING_AGG(DISTINCT km.keyword ORDER BY km.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY tk.production_year DESC) AS movie_rank
FROM 
    aka_name AS ak
JOIN 
    cast_info AS ci ON ak.person_id = ci.person_id
JOIN 
    ActorHierarchy AS ah ON ci.movie_id = ah.movie_id
JOIN 
    aka_title AS tk ON ci.movie_id = tk.id
LEFT JOIN 
    movie_companies AS mc ON tk.id = mc.movie_id
LEFT JOIN 
    movie_info AS mv ON tk.id = mv.movie_id
LEFT JOIN 
    movie_keyword AS mk ON tk.id = mk.movie_id
LEFT JOIN 
    keyword AS km ON mk.keyword_id = km.id
WHERE 
    tk.production_year IS NOT NULL 
    AND tk.production_year > 2000  -- Filtering for movies after the year 2000
GROUP BY 
    ak.name, tk.title, tk.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1  -- Ensuring the actor appeared in movies produced by more than one company
ORDER BY 
    movie_rank, avg_info_length DESC;
