WITH RecursiveTopMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 0
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count
    FROM 
        RecursiveTopMovies m
    WHERE 
        m.rn <= 5
        AND m.production_year BETWEEN 2000 AND 2023
),
KeywordMatches AS (
    SELECT 
        km.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword km
    JOIN 
        keyword k ON k.id = km.keyword_id
    GROUP BY 
        km.movie_id
),
FinalOutput AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.actor_count,
        COALESCE(km.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        KeywordMatches km ON fm.movie_id = km.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.keywords,
    (SELECT AVG(actor_count) FROM FilteredMovies) AS avg_actor_count,
    CASE 
        WHEN f.actor_count > (SELECT AVG(actor_count) FROM FilteredMovies) THEN 'Above Average'
        WHEN f.actor_count < (SELECT AVG(actor_count) FROM FilteredMovies) THEN 'Below Average'
        ELSE 'Average'
    END AS actor_count_comparison
FROM 
    FinalOutput f
ORDER BY 
    f.production_year DESC, f.actor_count DESC;