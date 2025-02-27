WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
ComplexCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast,
        SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FilteredMovies AS (
    SELECT 
        tm.title,
        cm.num_cast,
        cm.null_notes_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        ComplexCast cm ON tm.movie_id = cm.movie_id
)
SELECT 
    fm.title,
    fm.num_cast,
    CASE 
        WHEN fm.null_notes_count IS NULL THEN 'No Notes'
        ELSE 'Has Notes'
    END AS notes_status,
    COUNT(mk.keyword) AS keyword_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT DISTINCT movie_id FROM TopMovies)
GROUP BY 
    fm.title, fm.num_cast, fm.null_notes_count
HAVING 
    (fm.num_cast IS NOT NULL AND fm.num_cast > 0) OR 
    (fm.null_notes_count IS NOT NULL AND fm.null_notes_count > 1)
ORDER BY 
    keyword_count DESC, fm.title ASC
FETCH FIRST 10 ROWS ONLY;
