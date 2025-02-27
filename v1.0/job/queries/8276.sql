WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actors) AS actor_count
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    ac.actor_count
FROM 
    MovieDetails md
JOIN 
    ActorCount ac ON md.movie_id = ac.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    ac.actor_count DESC, md.production_year DESC
LIMIT 10;
