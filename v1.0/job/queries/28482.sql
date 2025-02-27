
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
), 
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ',') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mc.movie_id = mk.movie_id
    JOIN 
        aka_title mt ON mt.id = mk.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production Company')
    GROUP BY 
        mt.movie_id
),
FinalMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        mg.genres
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id
    ORDER BY 
        rm.production_year DESC, rm.cast_count DESC
)
SELECT 
    *,
    CASE 
        WHEN cast_count > 10 THEN 'High'
        WHEN cast_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS cast_size_category
FROM 
    FinalMovies
WHERE 
    genres IS NOT NULL
LIMIT 100;
