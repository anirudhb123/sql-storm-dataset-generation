WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        m.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        kind_id,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
FilteredMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        kt.kind,
        cm.name AS company_name
    FROM 
        TopMovies tm
    LEFT JOIN 
        kind_type kt ON tm.kind_id = kt.id
    LEFT JOIN 
        movie_companies mc ON tm.id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    WHERE 
        cm.country_code IS NOT NULL
),
MovieDetails AS (
    SELECT 
        fm.*,
        m.keyword,
        COALESCE(m.keyword, 'No keywords found') AS adjusted_keyword
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
    LEFT JOIN 
        keyword m ON mk.keyword_id = m.id
)
SELECT 
    md.title,
    md.production_year,
    md.kind,
    md.company_name,
    md.adjusted_keyword,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM complete_cast cc 
            WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = md.title LIMIT 1)
              AND cc.status_id IS NOT NULL
        ) THEN 'Complete Cast Available'
        ELSE 'No Complete Cast'
    END AS cast_status
FROM 
    MovieDetails md
WHERE 
    md.production_year >= (SELECT EXTRACT(YEAR FROM NOW()) - 5) 
    AND md.kind IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title DESC
LIMIT 50;

This SQL query performs multiple operations:
1. It uses Common Table Expressions (CTEs) to rank movies and select top entries based on production year.
2. It incorporates outer joins to pull company names along with movie details.
3. It employs window functions to number the rows and count distinct cast members related to each movie.
4. It applies conditional logic with CASE statements to provide a cast status.
5. It includes string and NULL logic to handle and modify output based on available keywords and completeness of cast data.
6. Finally, it filters and orders results to optimize performance for benchmarking scenarios.
