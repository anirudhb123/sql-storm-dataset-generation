WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
        m.info AS movie_info
    FROM 
        title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info m ON m.movie_id = t.id
    WHERE 
        t.production_year >= 1990  -- Focusing on movies from 1990 onward
    GROUP BY 
        t.id, t.title, t.production_year, m.info
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_names,
        keywords,
        company_types,
        movie_info,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        MovieDetails
    WHERE 
        movie_info IS NOT NULL AND 
        LENGTH(movie_info) > 0 -- Ensuring there is information available
)
SELECT 
    title,
    production_year,
    cast_names,
    keywords,
    company_types,
    movie_info
FROM 
    TopMovies
WHERE 
    rank <= 10 -- Get top 10 recent movies
ORDER BY 
    production_year DESC; -- Final ordering by production year
