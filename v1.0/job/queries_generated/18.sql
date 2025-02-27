WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_within_year
    FROM 
        title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.title, t.production_year
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
MovieKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keywords,
    CASE
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(DISTINCT c.id) FILTER (WHERE c.kind_id IS NOT NULL) AS company_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
GROUP BY 
    tm.title, tm.production_year, mk.keyword
ORDER BY 
    tm.production_year DESC, tm.title;
