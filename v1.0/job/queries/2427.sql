WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
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
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
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
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    fm.cast_count,
    COALESCE(STRING_AGG(DISTINCT a.name, ', '), 'No Cast') AS cast_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
WHERE 
    fm.cast_count > 0 
    AND fm.production_year IS NOT NULL 
GROUP BY 
    fm.title, fm.production_year, mk.keywords, fm.cast_count
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
