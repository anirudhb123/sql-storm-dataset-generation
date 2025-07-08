
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 10
),
MovieCast AS (
    SELECT 
        cm.movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        complete_cast cm
    INNER JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    GROUP BY 
        cm.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    mc.cast_count,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCast mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    mk.keywords IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title;
