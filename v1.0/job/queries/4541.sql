WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.id) DESC) AS rank_by_cast 
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info cc ON t.id = cc.movie_id
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
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id) AS distinct_actors,
    (SELECT COUNT(DISTINCT ci.role_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id
     AND ci.note IS NOT NULL) AS distinct_roles
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
