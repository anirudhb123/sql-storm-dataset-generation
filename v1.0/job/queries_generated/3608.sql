WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a 
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id 
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year,
        rm.cast_count,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS roles_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
    WHERE 
        rm.cast_count > 5
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
)
SELECT 
    f.title, 
    f.production_year, 
    f.cast_count, 
    f.roles_count,
    CASE 
        WHEN f.roles_count > 0 THEN 'Has Roles' 
        ELSE 'No Roles' 
    END AS role_presence,
    STRING_AGG(DISTINCT COALESCE(k.keyword, 'N/A'), ', ') AS keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.production_year = (SELECT production_year FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    f.title, f.production_year, f.cast_count, f.roles_count
HAVING 
    COUNT(k.id) > 0
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
