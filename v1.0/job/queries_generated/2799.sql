WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ca ON at.id = ca.movie_id
    WHERE 
        at.production_year IS NOT NULL
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
MovieKeywords AS (
    SELECT 
        at.title,
        mk.keyword
    FROM 
        aka_title at
    INNER JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    CASE 
        WHEN tm.production_year < 2010 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_type,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE production_year = tm.production_year)) AS info_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
ORDER BY 
    tm.production_year DESC, 
    tm.title;
