WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY mc.company_id DESC) AS rn
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywordCount AS (
    SELECT 
        tm.*,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywordCount mkc ON tm.movie_id = mkc.movie_id
)
SELECT 
    mwkc.movie_id,
    mwkc.title,
    mwkc.production_year,
    mwkc.keyword_count,
    COALESCE(aka.name, 'Unknown') AS director_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_notes_present
FROM 
    MoviesWithKeywordCount mwkc
LEFT JOIN 
    complete_cast cc ON mwkc.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name aka ON mwkc.movie_id = aka.person_id
WHERE 
    mwkc.keyword_count > 0
GROUP BY 
    mwkc.movie_id, mwkc.title, mwkc.production_year, aka.name
ORDER BY 
    mwkc.production_year DESC, mwkc.movie_id ASC;
