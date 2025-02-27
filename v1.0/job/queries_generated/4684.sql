WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name co ON mc.company_id = co.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    ci.company_name,
    ci.company_type,
    ci.info_count,
    COALESCE(
        (SELECT AVG(total_cast)
         FROM RankedMovies rm 
         WHERE rm.production_year = tm.production_year), 0) AS avg_cast_per_year
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.movie_id = ci.movie_id
ORDER BY 
    tm.production_year DESC, ci.info_count DESC;
