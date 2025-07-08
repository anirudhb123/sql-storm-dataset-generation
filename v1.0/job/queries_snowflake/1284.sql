
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM title
    LEFT JOIN cast_info ON title.id = cast_info.movie_id
    WHERE title.production_year IS NOT NULL
    GROUP BY title.id, title.title, title.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM RankedMovies rm
    WHERE rm.rank <= 10
),
MovieKeywords AS (
    SELECT 
        mv.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mv
    LEFT JOIN keyword k ON mv.keyword_id = k.id
    GROUP BY mv.movie_id
),
FinalResults AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM FilteredMovies f
    LEFT JOIN MovieKeywords mk ON f.movie_id = mk.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.keywords,
    CASE 
        WHEN fr.cast_count > 5 THEN 'Large cast'
        WHEN fr.cast_count BETWEEN 3 AND 5 THEN 'Medium cast'
        ELSE 'Small cast'
    END AS cast_size
FROM FinalResults fr
ORDER BY fr.production_year DESC, fr.cast_count DESC;
