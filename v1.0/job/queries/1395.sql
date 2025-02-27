WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
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
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mt
    JOIN 
        keyword AS k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)) AS distinct_cast_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.production_year = (SELECT production_year FROM aka_title WHERE id = mk.movie_id)
ORDER BY 
    tm.production_year DESC;
