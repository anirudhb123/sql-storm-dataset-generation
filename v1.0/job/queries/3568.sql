WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS role_count_rank,
        COUNT(c.id) AS total_roles
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        role_count_rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    TopMovies tm
LEFT JOIN 
    aka_title at ON tm.movie_title = at.title AND tm.production_year = at.production_year
LEFT JOIN 
    MovieKeywords mk ON at.id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
