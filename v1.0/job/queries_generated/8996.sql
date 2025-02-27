WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.id
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000 AND cast_count >= 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    STRING_AGG(DISTINCT name.name, ', ') AS leading_roles
FROM 
    FilteredMovies f
JOIN 
    cast_info ci ON f.movie_id = ci.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    aka_name name ON ci.person_id = name.person_id
WHERE 
    rt.role = 'Lead'
GROUP BY 
    f.movie_id, f.title, f.production_year, f.cast_count
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 10;
