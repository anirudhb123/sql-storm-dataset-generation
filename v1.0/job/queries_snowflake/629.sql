
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.company_count,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year = rm.production_year)) AS total_cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10 AND rm.company_count > 0
),
FinalOutput AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        fm.company_count,
        fm.total_cast_count,
        COALESCE(NULLIF(fm.total_cast_count, 0), -1) AS adjusted_cast_count
    FROM 
        FilteredMovies fm
    ORDER BY 
        fm.production_year DESC, fm.company_count DESC
)
SELECT 
    f.movie_title,
    f.production_year,
    f.company_count,
    f.total_cast_count,
    f.adjusted_cast_count,
    LISTAGG(DISTINCT CONCAT(c.note, ' ', p.info), '; ') AS additional_info
FROM 
    FinalOutput f
LEFT JOIN 
    complete_cast cc ON f.movie_title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    cast_info c ON cc.movie_id = c.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
GROUP BY 
    f.movie_title, f.production_year, f.company_count, f.total_cast_count, f.adjusted_cast_count
HAVING 
    f.company_count > 1 OR f.total_cast_count < 5
ORDER BY 
    f.production_year DESC, f.company_count DESC;
