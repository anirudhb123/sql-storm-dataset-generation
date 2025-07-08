WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT o.name) AS company_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name o ON mc.company_id = o.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_names,
        company_names,
        RANK() OVER (PARTITION BY keyword ORDER BY production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_names,
    company_names
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    keyword, production_year DESC;
