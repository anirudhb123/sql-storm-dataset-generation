WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(n.name, ' (', r.role, ')'), ', ') AS cast_members
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_members,
        RANK() OVER (ORDER BY cast_count DESC) AS ranking
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    cast_members
FROM 
    HighCastMovies
WHERE 
    ranking <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
