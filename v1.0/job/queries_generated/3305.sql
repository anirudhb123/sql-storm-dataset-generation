WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS has_ordered_cast,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE rank_per_year <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)

SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    COALESCE(SUM(mi.info || ': ' || mi.note), 'No Info') AS additional_info
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_info mi ON mwk.title = mi.info 
GROUP BY 
    mwk.title, mwk.production_year, mwk.keywords
ORDER BY 
    mwk.production_year DESC, mwk.title;
