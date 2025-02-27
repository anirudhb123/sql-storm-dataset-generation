WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mw.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mw
    LEFT JOIN 
        keyword k ON mw.keyword_id = k.id
    GROUP BY 
        mw.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        tm.cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    c.name AS company_name,
    c.country_code,
    cm.movie_id,
    c.id AS company_id,
    CASE 
        WHEN mi.note IS NULL THEN 'No Info'
        ELSE mi.note
    END AS movie_note,
    cmt.kind AS company_type,
    cm.production_year,
    cm.cast_count
FROM 
    movie_companies cm
JOIN 
    company_name c ON cm.company_id = c.id
JOIN 
    company_type cmt ON cm.company_type_id = cmt.id
LEFT JOIN 
    movie_info mi ON cm.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Note')
LEFT JOIN 
    CompleteMovieInfo cmp_movies ON cm.movie_id = cmp_movies.movie_id
WHERE 
    cm.note IS NOT NULL AND 
    EXTRACT(YEAR FROM CURRENT_DATE) - cm.production_year <= 5
ORDER BY 
    cm.production_year DESC, c.name;
