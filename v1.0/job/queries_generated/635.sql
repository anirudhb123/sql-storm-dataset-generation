WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopRankedMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 3
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) 
        FROM complete_cast cc 
        WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    ) AS complete_cast_count,
    CASE 
        WHEN mk.keywords IS NULL THEN 'Keywords not found'
        ELSE 'Keywords found'
    END AS keyword_status
FROM 
    TopRankedMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
ORDER BY 
    tm.production_year DESC,
    complete_cast_count DESC;
