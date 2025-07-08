
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(ci.person_id) AS total_cast,
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
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), 
MovieKeywords AS (
    SELECT 
        at.title AS movie_title,
        LISTAGG(kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        at.title
)
SELECT 
    tm.movie_title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No keywords') AS keywords, 
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_title = mk.movie_title
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC;
