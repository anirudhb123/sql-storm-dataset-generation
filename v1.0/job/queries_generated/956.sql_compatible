
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
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
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.production_year = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT at.title FROM aka_title at WHERE at.id = ci.movie_id)
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.company_names,
    COALESCE(NULLIF(md.actor_names, ''), 'No actors') AS actors_status,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
