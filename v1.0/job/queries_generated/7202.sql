WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS cast_member,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        STRING_AGG(rm.cast_member || ' (' || rm.role || ')', ', ') AS cast_details
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
    GROUP BY 
        rm.movie_title, rm.production_year
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_details,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c.name, ', ') AS companies
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_title = (SELECT title FROM aka_title WHERE production_year = md.production_year LIMIT 1)
LEFT JOIN 
    movie_companies mc ON md.movie_title = (SELECT title FROM aka_title WHERE production_year = md.production_year LIMIT 1)
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    md.movie_title, md.production_year
ORDER BY 
    md.production_year DESC;
