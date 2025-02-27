
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5 AND 
        rm.title_rank <= 3
),
MovieKeywords AS (
    SELECT 
        fk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword fk
    JOIN 
        keyword k ON fk.keyword_id = k.id
    GROUP BY 
        fk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(a.name, 'Unknown') AS main_actor
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id 
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
WHERE 
    ci.nr_order = 1
ORDER BY 
    fm.production_year DESC, 
    fm.title;
