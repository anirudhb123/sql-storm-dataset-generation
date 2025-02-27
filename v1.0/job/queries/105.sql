WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        at.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        at.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN tm.actor_count > 10 THEN 'Large Cast'
        WHEN tm.actor_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = (SELECT title FROM aka_title at WHERE at.movie_id = mk.movie_id LIMIT 1)
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
