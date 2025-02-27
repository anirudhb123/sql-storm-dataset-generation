WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywordInfo AS (
    SELECT 
        m.title,
        k.keyword,
        COALESCE(mi.info, 'No additional information') AS info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.title = mi.movie_id
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT i.id) AS info_count,
    CASE 
        WHEN COUNT(DISTINCT i.id) > 0 THEN 'Has additional info'
        ELSE 'No additional info'
    END AS info_status
FROM 
    MovieKeywordInfo m
LEFT JOIN 
    movie_info i ON m.title = i.movie_id
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, 
    info_count DESC;
