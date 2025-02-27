WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.kind_id = 1
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
FinalOutput AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.cast_count,
        COALESCE(ci.company_name, 'Unknown') AS production_company,
        COALESCE(ct.num_companies, 0) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyInfo ci ON tm.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
    LEFT JOIN 
        CompanyInfo ct ON tm.movie_title = (SELECT title FROM aka_title WHERE id = ct.movie_id LIMIT 1)
)
SELECT 
    movie_title,
    production_year,
    CAST(cast_count AS INTEGER) AS total_cast,
    production_company,
    company_count
FROM 
    FinalOutput
WHERE 
    production_year BETWEEN 2000 AND 2020
ORDER BY 
    production_year DESC, total_cast DESC;
