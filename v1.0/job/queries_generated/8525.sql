WITH MovieStats AS (
    SELECT 
        a.title AS Movie_Title,
        a.production_year AS Year,
        COUNT(DISTINCT ci.person_id) AS Cast_Count,
        STRING_AGG(DISTINCT c.name, ', ') AS Cast_Names,
        COUNT(DISTINCT mk.keyword) AS Keyword_Count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name c ON ci.person_id = c.imdb_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id
), CompanyStats AS (
    SELECT 
        a.id AS Movie_ID,
        c.name AS Company_Name,
        ct.kind AS Company_Type
    FROM 
        movie_companies a
    JOIN 
        company_name c ON a.company_id = c.imdb_id
    JOIN 
        company_type ct ON a.company_type_id = ct.id
), MovieDetails AS (
    SELECT 
        ms.Movie_Title,
        ms.Year,
        ms.Cast_Count,
        ms.Cast_Names,
        ms.Keyword_Count,
        ARRAY_AGG(DISTINCT cs.Company_Name || ' (' || cs.Company_Type || ')') AS Companies
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyStats cs ON ms.Movie_Title = (SELECT t.title FROM title t WHERE t.id = cs.Movie_ID)
    GROUP BY 
        ms.Movie_Title, ms.Year, ms.Cast_Count, ms.Cast_Names, ms.Keyword_Count
)
SELECT 
    Movie_Title,
    Year,
    Cast_Count,
    Cast_Names,
    Keyword_Count,
    Companies
FROM 
    MovieDetails
WHERE 
    Year >= 2000
ORDER BY 
    Year DESC, Cast_Count DESC;
