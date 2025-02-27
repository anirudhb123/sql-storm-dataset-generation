
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_year <= 3
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mc.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_names, 'No Companies') AS companies,
    COALESCE(md.keywords, 'No Keywords') AS movie_keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
