WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
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
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
),
MoviesWithKeyword AS (
    SELECT 
        tm.title,
        tm.production_year,
        pk.keyword,
        pk.keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        PopularKeywords pk ON tm.title = (SELECT title FROM aka_title WHERE id = pk.movie_id)
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword,
    mwk.keyword_count,
    COALESCE(cn.name, 'Unknown') AS company_name
FROM 
    MoviesWithKeyword mwk
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = mwk.title AND production_year = mwk.production_year)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mwk.keyword_count > 1
ORDER BY 
    mwk.production_year DESC, mwk.keyword_count DESC;
