WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title = mk.title
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword_count,
    CASE 
        WHEN mwk.keyword_count > 3 THEN 'Rich in Keywords'
        WHEN mwk.keyword_count = 0 THEN 'No Keywords'
        ELSE 'Moderate Keywords'
    END AS keyword_density,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    complete_cast cc ON mwk.title = cc.subject_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
WHERE 
    mwk.keyword_count IS NOT NULL
GROUP BY 
    mwk.title, mwk.production_year, mwk.keyword_count
HAVING 
    COUNT(DISTINCT ak.id) > 0
ORDER BY 
    mwk.production_year DESC, mwk.keyword_count DESC;
