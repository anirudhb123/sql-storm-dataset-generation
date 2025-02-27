
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
        STRING_AGG(DISTINCT c.name, ',') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ',') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        company_names,
        keywords
    FROM 
        MovieDetails
    WHERE 
        rn = 1
),

RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        company_names,
        keywords,
        RANK() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        FilteredMovies
)

SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    company_names,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
