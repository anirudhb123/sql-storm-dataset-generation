WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
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
        rm.cast_count > 5 AND rank <= 10
), 
MovieDetails AS (
    SELECT 
        fm.title,
        fm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year)
    GROUP BY 
        fm.title, fm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No cast') AS actors,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, md.keyword_count DESC
LIMIT 20;
