WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
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
        m.movie_id, 
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
CommonWithCallbacks AS (
    SELECT 
        m.title AS movie_title,
        COALESCE(GROUP_CONCAT(k.keyword), 'No Keywords') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywords k ON m.id = k.movie_id
    GROUP BY 
        m.title
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(NULLIF(cast_count.actor_count, 0), 'No Cast') AS actor_count,
    c.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(person_id) AS actor_count 
     FROM 
        cast_info 
     GROUP BY 
        movie_id) cast_count ON tm.title = cast_count.movie_id
LEFT JOIN 
    CommonWithCallbacks c ON tm.title = c.movie_title
ORDER BY 
    tm.production_year DESC, 
    cast_count.actor_count DESC;
