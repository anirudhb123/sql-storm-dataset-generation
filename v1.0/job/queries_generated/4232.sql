WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_percentage,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        has_notes_percentage
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        ci.note AS cast_note,
        mk.id AS keyword_id
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT ci.note) AS notes_count,
    CASE 
        WHEN COUNT(DISTINCT ci.note) = 0 THEN 'No notes'
        ELSE 'Notes available'
    END AS note_status
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.title, md.production_year
ORDER BY 
    md.production_year DESC;
