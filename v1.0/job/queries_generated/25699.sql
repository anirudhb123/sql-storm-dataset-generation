WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        aka_name c ON c.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name co ON co.id = mc.company_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.companies,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, array_length(md.cast_names, 1) DESC) AS rank
    FROM 
        MovieDetails md
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    tm.keywords,
    tm.companies
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10;

This query retrieves the top 10 movies released since 2000, ranked by their production year and the number of cast members, along with details about the cast, associated keywords, and production companies.
