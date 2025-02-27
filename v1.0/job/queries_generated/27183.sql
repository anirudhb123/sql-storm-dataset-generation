WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(ci.id) AS number_of_cast_members,
        STRING_AGG(an.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        number_of_cast_members,
        actors
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    tm.number_of_cast_members AS Number_of_Cast_Members,
    tm.actors AS Cast_Actors,
    ci.companies AS Production_Companies,
    ci.company_types AS Company_Types
FROM 
    TopMovies tm
JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.number_of_cast_members DESC;
