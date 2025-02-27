WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 10
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
),
FinalMovies AS (
    SELECT 
        fm.title,
        fm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.movie_id = mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    CASE 
        WHEN m.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era,
    COUNT(DISTINCT c.person_id) AS total_actors
FROM 
    FinalMovies m
LEFT JOIN 
    cast_info c ON c.movie_id = m.movie_id
GROUP BY 
    m.title, m.production_year, m.keywords
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    m.production_year DESC, m.title;
