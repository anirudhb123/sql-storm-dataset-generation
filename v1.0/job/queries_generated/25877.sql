WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL 
    GROUP BY 
        a.title, a.production_year
), 
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        cast_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_names,
    f.keywords,
    CASE 
        WHEN f.cast_count > 10 THEN 'Ensemble Cast'
        WHEN f.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_type
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
