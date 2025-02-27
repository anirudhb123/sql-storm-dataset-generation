WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rnk,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rnk <= 10
),
MovieCasting AS (
    SELECT 
        m.title,
        COUNT(ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count
    FROM 
        TopMovies m
    LEFT JOIN 
        cast_info ci ON m.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
    GROUP BY 
        m.title
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(m.cast_count, 0) AS cast_count,
    COALESCE(m.noted_cast_count, 0) AS noted_cast_count,
    CASE 
        WHEN m.cast_count > 20 THEN 'Large Cast'
        WHEN m.cast_count IS NULL THEN 'No Cast Info'
        ELSE 'Small to Medium Cast'
    END AS cast_size,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = m.title LIMIT 1)) AS info_count
FROM 
    MovieCasting m
ORDER BY 
    m.production_year DESC, m.title;
