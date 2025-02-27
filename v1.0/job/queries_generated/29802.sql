WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role AS role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
TopMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(SUM(mr.role_count), 0) AS total_roles
    FROM 
        aka_title m
    LEFT JOIN 
        MovieRoles mr ON m.id = mr.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id
    ORDER BY 
        total_roles DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_roles,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.id = mk.movie_id
ORDER BY 
    tm.total_roles DESC;
