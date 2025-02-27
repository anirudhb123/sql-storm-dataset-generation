WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
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
        rank_within_year <= 5
),
MovieDetail AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        ARRAY_AGG(DISTINCT m.company_id) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies m ON m.movie_id = cc.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    COALESCE(m.company_id, 'No Company') AS company_id,
    CASE WHEN md.production_year < 2000 THEN 'Classic' ELSE 'Modern' END AS era
FROM 
    MovieDetail md
LEFT JOIN 
    movie_companies m ON m.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1)
ORDER BY 
    md.production_year DESC, md.title;
