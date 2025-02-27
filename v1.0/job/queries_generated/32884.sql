WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        1 AS Level
    FROM 
        cast_info c
    WHERE 
        c.role_id = (SELECT id FROM role_type WHERE role = 'Lead')
    
    UNION ALL
    
    SELECT 
        c.person_id, 
        c.movie_id, 
        ah.Level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role != 'Lead')
),

MovieStats AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS Total_Cast, 
        COUNT(DISTINCT CASE WHEN r.role = 'Director' THEN c.person_id END) AS Total_Directors,
        AVG(CASE WHEN ah.Level IS NOT NULL THEN ah.Level ELSE 0 END) AS Avg_Actor_Hierarchy_Level
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        ActorHierarchy ah ON c.person_id = ah.person_id AND c.movie_id = ah.movie_id
    GROUP BY 
        t.title, 
        t.production_year
),

KeywordStats AS (
    SELECT 
        mk.movie_id, 
        array_agg(mk.keyword_id) AS Keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    ms.title,
    ms.production_year,
    ms.Total_Cast,
    ms.Total_Directors,
    ms.Avg_Actor_Hierarchy_Level,
    ks.Keywords
FROM 
    MovieStats ms
LEFT JOIN 
    KeywordStats ks ON ms.movie_id = ks.movie_id
WHERE 
    ms.Total_Cast > 5
ORDER BY 
    ms.production_year DESC,
    ms.Total_Cast DESC;

This query does the following:

1. **Recursive CTE (ActorHierarchy)**: Generates a hierarchy of actors based on their roles in films. It starts with Lead actors and then includes supporting roles, creating levels of hierarchy.
  
2. **MovieStats CTE**: Aggregates movie data by counting distinct cast members and directors, and computes the average hierarchy level of actors involved in films.

3. **KeywordStats CTE**: Aggregates keywords associated with each movie into an array, enhancing the information about each movie.

4. The final `SELECT` statement retrieves results from the `MovieStats` while also including keywords, filtering for movies that have more than five cast members, and sorts the output by the year of production and the total number of cast members. 

This approach efficiently combines multiple SQL constructs to analyze movie data and actor participation trends.
