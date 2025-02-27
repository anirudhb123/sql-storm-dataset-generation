WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_aka_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        keywords,
        companies,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS row_num
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.keywords,
    tm.companies,
    tm.cast_count,
    c.role AS main_role
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    tm.row_num <= 10
ORDER BY 
    tm.cast_count DESC, tm.movie_title;
