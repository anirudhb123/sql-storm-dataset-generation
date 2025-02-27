WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
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
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(GROUP_CONCAT(DISTINCT cn.name), 'No Companies') AS production_companies,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.production_companies,
    md.keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year)) AS complete_cast_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
