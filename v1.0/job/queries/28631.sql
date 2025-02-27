
WITH MovieRoleCount AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        TRIM(mk.keywords) AS keywords,
        mrc.role_name,
        mrc.role_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieRoleCount mrc ON tm.movie_id = mrc.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.keywords,
    dmi.role_name,
    dmi.role_count,
    CASE 
        WHEN dmi.role_count IS NULL THEN 'No roles found'
        ELSE CONCAT(dmi.role_name, ' appears ', dmi.role_count, ' times in this movie.')
    END AS role_info
FROM 
    DetailedMovieInfo dmi
ORDER BY 
    dmi.production_year DESC, dmi.role_count DESC;
