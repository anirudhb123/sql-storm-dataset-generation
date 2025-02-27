WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rnk
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rnk <= 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        cm.company_count,
        COALESCE(ti.info, 'No additional info') AS additional_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyMovies cm ON tm.movie_id = cm.movie_id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        (SELECT 
             movie_id, STRING_AGG(info, '; ') AS info FROM movie_info GROUP BY movie_id) AS ti ON ti.movie_id = tm.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.company_count,
    fr.additional_info
FROM 
    FinalResults fr
WHERE 
    fr.company_count IS NOT NULL OR fr.additional_info IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title ASC;
