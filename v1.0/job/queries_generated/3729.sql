WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, 
        t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON rm.title = c.movie_id
    WHERE 
        rm.rank_by_cast_count <= 5
    GROUP BY 
        rm.title, 
        rm.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC;
