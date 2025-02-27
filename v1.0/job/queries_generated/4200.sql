WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
DistinctKeywords AS (
    SELECT DISTINCT 
        mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies
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
    mk.keyword,
    mc.companies,
    COALESCE(NULLIF(tm.production_year, 2020), 'Not in 2020') AS production_status,
    CASE 
        WHEN tm.production_year IS NOT NULL THEN 'Released'
        ELSE 'Not Released'
    END AS release_status
FROM 
    TopRankedMovies tm
LEFT JOIN 
    DistinctKeywords mk ON tm.production_year = (SELECT MAX(production_year) FROM TopRankedMovies) 
LEFT JOIN 
    MovieCompanies mc ON tm.title = mc.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
