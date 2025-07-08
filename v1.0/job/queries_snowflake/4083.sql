
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
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
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS companies_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    rm.num_cast_members, 
    COALESCE(cc.companies_count, 0) AS companies_count,
    CASE 
        WHEN cc.companies_count IS NULL THEN 'No Companies'
        ELSE 'Has Companies'
    END AS company_status
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyCount cc ON cc.movie_id IN (SELECT t.id FROM aka_title t WHERE t.title = tm.title)
JOIN 
    RankedMovies rm ON rm.title = tm.title AND rm.production_year = tm.production_year
ORDER BY 
    tm.production_year DESC, 
    rm.num_cast_members DESC;
