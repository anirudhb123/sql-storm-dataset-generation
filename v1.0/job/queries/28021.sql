
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
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
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        a.person_id AS person_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        ARRAY_AGG(DISTINCT ci.movie_id) AS movies,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        MovieDetails m ON t.id = m.movie_id
    GROUP BY 
        a.person_id, a.name
),
BenchmarkResults AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        pd.actor_name,
        pd.roles,
        pd.movie_titles,
        md.keywords,
        md.companies
    FROM 
        MovieDetails md
    JOIN 
        PersonDetails pd ON pd.movies @> ARRAY[md.movie_id]
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    roles,
    keywords,
    companies
FROM 
    BenchmarkResults
ORDER BY 
    production_year DESC, movie_title;
