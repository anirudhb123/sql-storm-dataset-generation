WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END), 0) AS avg_order,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.avg_order,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
), MovieKeywords AS (
    SELECT 
        km.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword km
    JOIN 
        keyword k ON km.keyword_id = k.id
    GROUP BY 
        km.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.avg_order,
    fm.total_cast,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;
