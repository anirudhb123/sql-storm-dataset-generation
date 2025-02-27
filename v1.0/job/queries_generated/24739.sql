WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        mk.keyword, 
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, 
        tm.production_year, 
        mk.keyword
),
FinalSelection AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.keyword,
        CASE 
            WHEN md.companies IS NULL THEN 'No Companies'
            ELSE 'Companies Available'
        END AS company_status
    FROM 
        MovieDetails md 
    WHERE 
        md.keyword IS NOT NULL AND
        (md.production_year BETWEEN 2000 AND 2023)
)
SELECT 
    fs.title,
    fs.production_year,
    fs.keyword,
    fs.company_status
FROM 
    FinalSelection fs
WHERE 
    fs.company_status = 'Companies Available'
ORDER BY 
    fs.production_year DESC, 
    fs.title ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

