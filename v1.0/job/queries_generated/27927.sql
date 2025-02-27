WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        k.keyword AS top_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        company_count,
        cast_names,
        top_keyword
    FROM 
        RankedMovies
    WHERE 
        company_count > 2 AND production_year >= 2000
)

SELECT 
    title,
    production_year,
    company_count,
    cast_names,
    top_keyword
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, title ASC
LIMIT 50;
