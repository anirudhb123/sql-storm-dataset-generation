
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_companies mc ON fm.production_year = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        fm.title, fm.production_year
)
SELECT 
    fd.title, 
    fd.production_year, 
    fd.cast_count, 
    COALESCE(md.company_count, 0) AS company_count, 
    CASE 
        WHEN COALESCE(md.company_count, 0) > 0 THEN 'Companies: ' || COALESCE(md.company_names, '') 
        ELSE 'No companies listed' 
    END AS company_info
FROM 
    FilteredMovies fd
LEFT JOIN 
    MovieDetails md ON fd.title = md.title AND fd.production_year = md.production_year
WHERE 
    (fd.cast_count IS NOT NULL AND fd.cast_count > 0)
ORDER BY 
    fd.production_year DESC, fd.cast_count DESC;
