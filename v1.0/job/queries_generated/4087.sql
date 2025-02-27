WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
DirectorCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM 
        movie_companies m
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    WHERE 
        ct.kind = 'Director'
    GROUP BY 
        m.movie_id
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
    COALESCE(dc.director_count, 0) AS number_of_directors,
    mk.keywords,
    CASE 
        WHEN dc.director_count IS NULL THEN 'No Directors'
        WHEN dc.director_count > 1 THEN 'Multiple Directors'
        ELSE 'Single Director' 
    END AS director_status
FROM 
    TopMovies tm
LEFT JOIN 
    DirectorCounts dc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = dc.movie_id)
LEFT JOIN 
    MovieKeywords mk ON dc.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    number_of_directors DESC;
