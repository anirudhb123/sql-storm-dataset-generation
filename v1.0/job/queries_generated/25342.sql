WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ak.name, 'Unknown') AS aka_name,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, ak.name
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_name,
        cast_count,
        keywords,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.aka_name,
    fm.cast_count,
    fm.keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 5
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
