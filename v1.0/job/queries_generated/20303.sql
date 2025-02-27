WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rank_per_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 10
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS directors
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        name cn ON ci.person_id = cn.id
    WHERE 
        rt.role = 'director'
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        di.directors,
        mk.keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        DirectorInfo di ON tm.movie_id = di.movie_id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.directors, 'Unknown Directors') AS directors,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        WHEN m.production_year < 2000 THEN 'Classic'
        WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    (SELECT COUNT(*)
     FROM cast_info ci
     WHERE ci.movie_id = m.movie_id AND ci.note IS NULL) AS null_notes_count
FROM 
    MoviesWithDetails m
WHERE 
    m.title IS NOT NULL
    AND (m.keywords IS NULL OR m.keywords LIKE '%action%')
ORDER BY 
    m.production_year DESC,
    m.title ASC
LIMIT 50;
