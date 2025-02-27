WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        1 AS depth
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.name ILIKE 'Johnny Depp%'  
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        ci.movie_id,
        ah.depth + 1
    FROM 
        cast_info ci
    INNER JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
)

SELECT 
    an.name AS Actor_Name,
    COUNT(DISTINCT ah.movie_id) AS Total_Movies,
    ARRAY_AGG(DISTINCT t.title) AS Movie_Titles,
    SUM(CASE WHEN t.production_year IS NOT NULL THEN 1 ELSE 0 END) AS Movies_Released,
    AVG(t.production_year) AS Avg_Production_Year,
    STRING_AGG(DISTINCT cn.name, ', ') AS Companies_Produced,
    ROW_NUMBER() OVER (PARTITION BY an.name ORDER BY COUNT(DISTINCT ah.movie_id) DESC) AS Actor_Rank
FROM 
    ActorHierarchy ah
INNER JOIN 
    aka_name an ON ah.person_id = an.person_id
INNER JOIN 
    title t ON ah.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON ah.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    an.name
HAVING 
    COUNT(DISTINCT ah.movie_id) > 5  
ORDER BY 
    Total_Movies DESC, Avg_Production_Year DESC;