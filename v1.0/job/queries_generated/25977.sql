WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        a.name AS lead_actor,
        a.imdb_index AS actor_index,
        pc.kind AS production_company,
        ci.kind AS cast_role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name pc ON mc.company_id = pc.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
        AND k.keyword ILIKE '%drama%'
        AND ci.nr_order = 1
),
AggregatedMovieData AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        ARRAY_AGG(DISTINCT md.movie_keyword) AS keywords,
        STRING_AGG(DISTINCT md.lead_actor, ', ') AS lead_actors,
        STRING_AGG(DISTINCT md.production_company, ', ') AS production_companies,
        COUNT(DISTINCT md.cast_role) AS total_roles
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year
)
SELECT 
    movie_title,
    STRING_AGG(DISTINCT production_companies, ', ') AS production_companies,
    production_year,
    lead_actors,
    total_roles,
    keywords
FROM 
    AggregatedMovieData
GROUP BY 
    movie_title, production_year, lead_actors, total_roles
ORDER BY 
    production_year DESC, movie_title;
