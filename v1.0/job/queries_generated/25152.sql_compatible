
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(mk.keywords, ARRAY[]::varchar[]) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.cast_count,
    STRING_AGG(mwk.keywords::varchar, ', ') AS all_keywords
FROM 
    MoviesWithKeywords mwk
GROUP BY 
    mwk.movie_id, mwk.title, mwk.production_year, mwk.cast_count
ORDER BY 
    mwk.cast_count DESC, mwk.production_year DESC
LIMIT 10;
