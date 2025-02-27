WITH Performance_Benchmark AS (
    SELECT 
        title.title AS Movie_Title,
        aka_name.name AS Actor_Name,
        COUNT(DISTINCT cast_info.id) AS Cast_Count,
        COUNT(DISTINCT movie_keyword.keyword_id) AS Keyword_Count,
        MIN(movie_info.info) AS First_Info,
        MAX(movie_info.info) AS Last_Info,
        STRING_AGG(DISTINCT company_name.name, ', ') AS Production_Companies,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS Keywords
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        company_name ON movie_companies.company_id = company_name.id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.title, aka_name.name
)
SELECT 
    Movie_Title, 
    Actor_Name, 
    Cast_Count, 
    Keyword_Count, 
    First_Info, 
    Last_Info, 
    Production_Companies,
    Keywords
FROM 
    Performance_Benchmark
ORDER BY 
    Movie_Title, Actor_Name;
