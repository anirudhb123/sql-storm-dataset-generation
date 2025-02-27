WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (
            SELECT title 
            FROM aka_title 
            WHERE id = mk.movie_id
        )
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT pc.info) AS person_info_count,
    SUM(COALESCE(mx.info_type_id, 0)) AS total_info_type_count
FROM 
    MoviesWithKeywords m
LEFT JOIN 
    complete_cast cc ON m.title = (
        SELECT title 
        FROM aka_title 
        WHERE id = cc.movie_id
    )
LEFT JOIN 
    person_info pc ON cc.subject_id = pc.person_id
LEFT JOIN 
    movie_info mx ON cc.movie_id = mx.movie_id
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, m.title;
