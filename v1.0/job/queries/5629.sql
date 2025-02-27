WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS ranking
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE
        rm.ranking <= 5
    ORDER BY 
        rm.production_year DESC, rm.cast_count DESC
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalResults AS (
    SELECT
        tm.title AS Movie_Title,
        tm.production_year AS Production_Year,
        tm.cast_count AS Cast_Count,
        cd.company_name AS Production_Company,
        cd.company_type AS Company_Type
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyDetails cd ON tm.movie_id = cd.movie_id
)
SELECT 
    Movie_Title, 
    Production_Year, 
    Cast_Count, 
    STRING_AGG(DISTINCT Production_Company, ', ') AS Production_Companies,
    STRING_AGG(DISTINCT Company_Type, ', ') AS Company_Types
FROM 
    FinalResults
GROUP BY 
    Movie_Title, 
    Production_Year, 
    Cast_Count
ORDER BY 
    Production_Year DESC, 
    Cast_Count DESC;
