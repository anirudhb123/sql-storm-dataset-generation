WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        t.id, t.title, t.production_year
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
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mi.info AS movie_info,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year, mk.keyword, mi.info
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.movie_info,
    md.company_count
FROM 
    MovieDetails md
WHERE 
    md.movie_info IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC 
LIMIT 10;
