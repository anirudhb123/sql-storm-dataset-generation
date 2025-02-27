WITH MovieStatistics AS (
    SELECT 
        a.title AS Movie_Title,
        t.kind AS Movie_Kind,
        t.production_year AS Year,
        COUNT(DISTINCT ci.person_id) AS Total_Cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS Total_Role_Count,
        AVG(COALESCE(mk.keyword_count, 0)) AS Average_Keywords
    FROM 
        aka_title t
    LEFT JOIN 
        title a ON a.id = t.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(keyword_id) AS keyword_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) mk ON mk.movie_id = t.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023 
        AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%') OR 
             t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Comedy%'))
    GROUP BY 
        a.title, t.kind, t.production_year
),
RoleStatistics AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS Role_Participants
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
)
SELECT 
    ms.Movie_Title,
    ms.Movie_Kind,
    ms.Year,
    ms.Total_Cast,
    ms.Total_Role_Count,
    rs.Role_Participants,
    (SELECT COUNT(DISTINCT ci.id) FROM cast_info ci WHERE ci.movie_id = t.movie_id) AS Total_Actors_For_Title,
    CASE 
        WHEN ms.Total_Cast > 10 THEN 'Large Cast'
        WHEN ms.Total_Cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS Cast_Size_Category
FROM 
    MovieStatistics ms
LEFT JOIN 
    RoleStatistics rs ON rs.role_id = ANY(ARRAY(SELECT DISTINCT role_id FROM cast_info WHERE movie_id IN (SELECT movie_id FROM aka_title t WHERE t.production_year = ms.Year)))
ORDER BY 
    Year DESC, Total_Cast DESC
LIMIT 100;
