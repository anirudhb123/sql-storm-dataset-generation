
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000   
    GROUP BY 
        t.id, t.title, t.production_year
),
AggregatedInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.actors,
        CASE 
            WHEN md.production_year < 2010 THEN 'Classic'
            ELSE 'Modern'
        END AS era
    FROM 
        MovieDetails md
)
SELECT 
    ai.movie_id,
    ai.title,
    ai.production_year,
    ai.keywords,
    ai.companies,
    ai.actors,
    ai.era,
    COUNT(DISTINCT ai.actors) AS actor_count
FROM 
    AggregatedInfo ai
GROUP BY 
    ai.movie_id, ai.title, ai.production_year, ai.keywords, ai.companies, ai.actors, ai.era
ORDER BY 
    ai.production_year DESC, actor_count DESC
LIMIT 50;
