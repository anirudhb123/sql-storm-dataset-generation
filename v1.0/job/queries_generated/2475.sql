WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS notes_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY k.keyword) AS keyword_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FinalMovieStats AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.keyword,
        mw.keyword_rank,
        MAX(m.total_cast) AS max_cast,
        SUM(m.notes_count) AS total_notes
    FROM 
        MoviesWithKeywords mw
    JOIN 
        RankedMovies m ON mw.title = m.title AND mw.production_year = m.production_year
    GROUP BY 
        mw.title, mw.production_year, mw.keyword, mw.keyword_rank
)
SELECT 
    title,
    production_year,
    STRING_AGG(keyword, ', ') AS keywords,
    max_cast,
    total_notes
FROM 
    FinalMovieStats
WHERE 
    total_notes > 0 
GROUP BY 
    title, production_year, max_cast
ORDER BY 
    production_year DESC, max_cast DESC;
