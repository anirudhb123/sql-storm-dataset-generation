WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
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
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT mw.id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_keyword mw ON tm.title = (SELECT title FROM aka_title WHERE id = mw.movie_id)
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.companies, 'No companies') AS companies,
    COALESCE(md.actors, 'No actors') AS actors,
    md.keyword_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
