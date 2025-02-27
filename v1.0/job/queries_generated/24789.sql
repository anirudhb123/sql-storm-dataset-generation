WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, total_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 5 -- Top 5 movies per production year
),
MovieKeywordDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieInfoWithNotes AS (
    SELECT 
        m.movie_id,
        COALESCE(mi.info, 'No info') AS info,
        COALESCE(mi.note, 'No note') AS note
    FROM 
        movie_info m
    FULL OUTER JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info IS NOT NULL OR mi.note IS NOT NULL
),
FinalOutput AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.total_cast,
        mwd.keywords,
        mw.notes
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywordDetails mwd ON tm.movie_id = mwd.movie_id
    LEFT JOIN 
        MovieInfoWithNotes mw ON tm.movie_id = mw.movie_id
)
SELECT 
    *,
    CASE 
        WHEN total_cast > 15 THEN 'Large Cast'
        WHEN total_cast BETWEEN 5 AND 15 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN title ILIKE '%epic%' THEN 'Epic Genre'
        ELSE 'Other Genre'
    END AS title_genre_evaluation
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, total_cast DESC
LIMIT 100;
