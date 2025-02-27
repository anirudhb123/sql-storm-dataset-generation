WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
      AND 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(a.name, 'Unknown') AS Actor_Name,
    COUNT(DISTINCT kc.keyword) AS Keyword_Count,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS Cast_Count,
    COUNT(DISTINCT mco.company_id) AS Company_Count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS Movie_Rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mco ON m.movie_id = mco.movie_id
WHERE 
    m.production_year >= 2000 
    AND (m.production_year <= 2023 OR m.production_year IS NULL)
GROUP BY 
    m.title, m.production_year, a.name
ORDER BY 
    Movie_Rank, Production_Year DESC;
