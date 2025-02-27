WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
FilteredMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        string_agg(DISTINCT cn.name, ', ') AS company_names,
        SUM(mk.keyword_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.company_names, 'No Companies') AS companies,
    CASE 
        WHEN fm.keyword_count IS NULL THEN 'No Keywords' 
        ELSE fm.keyword_count::text 
    END AS keyword_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.keyword_count DESC;
