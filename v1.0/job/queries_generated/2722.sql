WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS company_person_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    cd.company_name,
    cd.company_type,
    cd.company_person_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
ORDER BY 
    tm.production_year DESC, cd.company_person_count DESC;
