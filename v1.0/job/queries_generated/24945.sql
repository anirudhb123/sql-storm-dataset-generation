WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDensity AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.company_count,
        cd.companies,
        CASE 
            WHEN cd.company_count > 5 THEN 'High'
            WHEN cd.company_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS company_density
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDensity cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.title_rank = 1
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.companies,
    tm.company_density,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(CASE 
            WHEN ci.note IS NOT NULL AND LENGTH(ci.note) > 5 THEN 1 
            ELSE NULL 
        END) AS avg_note_length,
    (SELECT 
        COUNT(*) 
     FROM 
        complete_cast cc 
     WHERE 
        cc.movie_id = tm.movie_id
    ) AS complete_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.title, tm.production_year, tm.company_count, tm.companies, tm.company_density, mk.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    tm.production_year DESC, tm.title;
