WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN ci.kind IS NOT NULL THEN ci.kind END) AS average_role,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.title IS NOT NULL 
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count, 
        average_role
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5  -- Only include movies with more than 5 cast members
)
SELECT 
    f.title, 
    f.production_year, 
    f.cast_count,
    COALESCE(m.info, 'No details available') AS movie_info
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_info m ON f.production_year = m.movie_id
WHERE 
    f.production_year IN (SELECT DISTINCT production_year FROM RankedMovies WHERE rank <= 10)
ORDER BY 
    f.cast_count DESC, f.production_year;
