WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        r.role AS cast_role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY p.name) AS role_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        a.production_year >= 2000  
)

SELECT 
    rm.movie_title,
    STRING_AGG(DISTINCT rm.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT CONCAT(rm.cast_role, ': ', ms.name), '; ') AS cast_details
FROM 
    RankedMovies rm
JOIN 
    aka_name ms ON rm.movie_id = ms.id
GROUP BY 
    rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.movie_title;