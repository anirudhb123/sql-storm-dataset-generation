WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast = 1
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
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        mk.keywords,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.title, tm.production_year, mk.keywords
    ORDER BY 
        tm.production_year DESC
)
SELECT 
    *,
    CONCAT('Movie: ', title, ', Year: ', production_year, ', Keywords: ', COALESCE(keywords, 'None'), ', Total Cast: ', total_cast) AS movie_description
FROM 
    FinalOutput;
