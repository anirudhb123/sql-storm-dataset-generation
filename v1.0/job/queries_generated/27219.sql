WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        name p ON ci.person_id = p.imdb_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword ILIKE '%drama%'
),

RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.production_year DESC) AS year_rank
    FROM 
        MovieDetails md
)

SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    company_name,
    person_name,
    person_role
FROM 
    RankedMovies
WHERE 
    year_rank <= 5
ORDER BY 
    production_year DESC, 
    title;

This SQL query benchmarks string processing by utilizing various string manipulation functions and JOIN operations across multiple tables. It selects movies produced from the year 2000 onwards that are categorized under the "drama" genre, and it retrieves relevant details about each movie along with associated keywords, companies involved, and actors along with their roles. The results are partitioned and ranked by production year, providing the top 5 entries per year for easier assessment of movie characteristics.
