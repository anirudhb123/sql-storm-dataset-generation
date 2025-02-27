
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COALESCE(SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_names,
    md.info_count,
    CASE 
        WHEN md.info_count > 0 THEN 'Has Info'
        ELSE 'No Info'
    END AS info_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.info_count DESC;
