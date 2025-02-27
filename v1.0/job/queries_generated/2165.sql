WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.actor_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title = mk.title
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.keywords
FROM 
    FinalOutput f
WHERE 
    f.actor_count >= (SELECT AVG(actor_count) FROM FinalOutput) -- only movies with above average actor count
ORDER BY 
    f.production_year DESC, f.actor_count DESC;
