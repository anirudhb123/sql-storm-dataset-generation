WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keywords, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) as rank
    FROM 
        RankedMovies
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.keywords,
    m.cast_count
FROM 
    TopMovies m
WHERE 
    m.rank <= 10 
ORDER BY 
    m.cast_count DESC;