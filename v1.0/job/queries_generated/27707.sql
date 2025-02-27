WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS cast_role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year >= 2000
),
GroupedRoles AS (
    SELECT
        movie_title,
        production_year,
        STRING_AGG(DISTINCT cast_role, ', ') AS roles,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies
    FROM 
        RankedMovies
    WHERE 
        rn = 1
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    roles,
    keywords,
    companies
FROM 
    GroupedRoles
ORDER BY 
    production_year DESC, movie_title;
