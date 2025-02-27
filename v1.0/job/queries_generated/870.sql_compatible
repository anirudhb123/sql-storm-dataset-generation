
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS movie_rank,
        COUNT(ci.id) AS cast_count
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
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 3
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year, tm.cast_count
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(md.actor_names, 'No actors listed') AS actor_names,
    COALESCE(md.company_count, 0) AS company_count,
    CASE 
        WHEN md.company_count > 5 THEN 'High Production'
        WHEN md.company_count BETWEEN 1 AND 5 THEN 'Medium Production'
        ELSE 'No Production'
    END AS production_scale
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
