WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_name ak ON t.id = ak.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        companies,
        keywords,
        DENSE_RANK() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    companies,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;

This query retrieves the top 10 movies from the `aka_title` table sorted by their production year. For each movie, it collects alternative names from the `aka_name` table, associated companies from the `company_name` table, and keywords from the `keyword` table, grouping them appropriately. The `DENSE_RANK()` function is used to rank movies by production year.
