WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(m.year, 'Unknown') AS year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name cn ON c.person_id = cn.person_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        d.movie_id,
        d.title,
        d.year,
        d.cast_count,
        d.cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        MovieDetails d
    LEFT JOIN 
        movie_keyword mk ON d.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        d.movie_id, d.title, d.year, d.cast_count, d.cast_names
)
SELECT 
    m.title,
    m.year,
    m.cast_count,
    m.cast_names,
    COALESCE(m.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN m.cast_count > 5 THEN 'Large Cast'
        WHEN m.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MoviesWithKeywords m
WHERE 
    m.year = (SELECT MAX(year) FROM MovieDetails WHERE year IS NOT NULL)
ORDER BY 
    m.cast_count DESC, m.title ASC;
