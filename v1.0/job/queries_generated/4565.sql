WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ARRAY_AGG(DISTINCT an.name) AS actor_names,
    (SELECT COUNT(DISTINCT mc.company_id)
     FROM movie_companies mc 
     WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)) AS company_count,
    COALESCE(NULLIF(STRING_AGG(DISTINCT mk.keyword, ', '), ''), 'No Keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.production_year = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
GROUP BY 
    tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
