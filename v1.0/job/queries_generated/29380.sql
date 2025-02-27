WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoleStats AS (
    SELECT 
        ci.movie_id,
        r.role AS person_role,
        COUNT(ci.person_id) AS role_count,
        STRING_AGG(CONCAT(na.name, ' (', na.imdb_index, ')'), ', ') AS cast_details
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id, r.role
),
TopKeywords AS (
    SELECT 
        rk.movie_id,
        rk.title,
        rk.production_year,
        rk.keyword_count,
        rk.keywords,
        pr.person_role,
        pr.role_count,
        pr.cast_details
    FROM 
        RankedMovies rk
    JOIN 
        PersonRoleStats pr ON rk.movie_id = pr.movie_id
    WHERE 
        rk.rank <= 5
)
SELECT 
    tk.title,
    tk.production_year,
    tk.keyword_count,
    tk.keywords,
    tk.person_role,
    tk.role_count,
    tk.cast_details
FROM 
    TopKeywords tk
ORDER BY 
    tk.production_year DESC, 
    tk.keyword_count DESC;
