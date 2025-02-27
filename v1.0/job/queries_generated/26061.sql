WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        c.name AS company_name,
        i.info AS additional_info
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        keyword k ON mi.info_type_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info_idx i ON t.id = i.movie_id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
AggregatedResults AS (
    SELECT 
        title_id,
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT additional_info, '; ') AS additional_info
    FROM 
        MovieDetails
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    title_id,
    title,
    production_year,
    actors,
    keywords,
    companies,
    additional_info
FROM 
    AggregatedResults
ORDER BY 
    production_year DESC, title;
