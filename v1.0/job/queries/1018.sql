WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    fm.production_year DESC, cast_count DESC;
