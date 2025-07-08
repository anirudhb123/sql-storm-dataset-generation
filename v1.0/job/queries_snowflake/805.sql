
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COALESCE(k.keyword, 'No Keywords') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        keywords 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_movies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    f.title AS Movie_Title,
    f.production_year AS Production_Year,
    f.keywords AS Keywords,
    COALESCE(ci.company_name, 'Independent') AS Company_Name,
    COALESCE(ci.company_type, 'N/A') AS Company_Type,
    ci.total_movies AS Number_of_Movies_Produced
FROM 
    FilteredMovies f
LEFT JOIN 
    CompanyInfo ci ON f.title = (SELECT a.title FROM aka_title a WHERE a.id = ci.movie_id)
ORDER BY 
    f.production_year DESC, f.title;
