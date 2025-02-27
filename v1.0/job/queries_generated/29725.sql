WITH RankedMovies AS (
    SELECT 
        title.title AS Movie_Title,
        title.production_year AS Production_Year,
        COUNT(DISTINCT cast_info.person_id) AS Cast_Count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS Cast_Names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS Keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS Rank
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year > 2000
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        Movie_Title,
        Production_Year,
        Cast_Count,
        Cast_Names,
        Keywords
    FROM 
        RankedMovies
    WHERE 
        Rank <= 10
)
SELECT 
    TM.Movie_Title,
    TM.Production_Year,
    TM.Cast_Count,
    TM.Cast_Names,
    TM.Keywords,
    info.info AS Additional_Info
FROM 
    TopMovies AS TM
LEFT JOIN 
    movie_info ON TM.Movie_Title = movie_info.info 
LEFT JOIN 
    info_type ON movie_info.info_type_id = info_type.id
WHERE 
    info_type.info = 'Synopsis'
ORDER BY 
    TM.Production_Year DESC;
