WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
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
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        km.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword km
    INNER JOIN 
        keyword k ON km.keyword_id = k.id
    GROUP BY 
        km.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(DISTINCT m.info) AS info_details
    FROM 
        movie_info mi
    INNER JOIN 
        movie_info_idx m ON mi.movie_id = m.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.info_details, '{}') AS info_details
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON tm.movie_id = mi.movie_id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, tm.title;
