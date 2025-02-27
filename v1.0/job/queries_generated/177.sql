WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        cm.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovies cm ON rm.title_id = cm.movie_id
    WHERE 
        rm.cast_count > 5
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.companies, 'No Companies') AS company_list,
    md.cast_count,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            movie_info mi
        WHERE 
            mi.movie_id = md.title_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
    ), 0) AS genre_count
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
