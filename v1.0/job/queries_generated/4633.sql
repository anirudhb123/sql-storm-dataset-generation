WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        rank,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FullMovieDetails AS (
    SELECT 
        m.movie_id, 
        m.title, 
        m.production_year,
        c.company_name,
        c.company_type,
        m.cast_count
    FROM 
        TopMovies m
    LEFT JOIN 
        CompanyDetails c ON m.movie_id = c.movie_id
)
SELECT 
    f.movie_id, 
    f.title, 
    f.production_year,
    COALESCE(f.company_name, 'Independent') AS company_name,
    f.company_type,
    f.cast_count,
    CASE 
        WHEN f.cast_count > 10 THEN 'Large Cast'
        WHEN f.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    FullMovieDetails f
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
