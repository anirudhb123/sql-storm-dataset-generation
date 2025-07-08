
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count 
    FROM RankedMovies 
    WHERE rank_per_year <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.title
),
MoviesWithRoles AS (
    SELECT 
        t.title, 
        COALESCE(ARRAY_AGG(DISTINCT rt.role), ARRAY_CONSTRUCT('No roles')) AS roles
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY t.title
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    mk.keywords,
    mwr.roles
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
LEFT JOIN 
    MoviesWithRoles mwr ON tm.title = mwr.title
ORDER BY 
    tm.production_year ASC, 
    tm.cast_count DESC;
