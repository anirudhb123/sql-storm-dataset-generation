
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
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.actors,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        MovieDetails md
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.companies,
    mi.actors,
    mi.era,
    COUNT(DISTINCT mi.actors) AS actor_count
FROM 
    MovieInfo mi
WHERE 
    mi.production_year >= 2010
GROUP BY 
    mi.movie_id, mi.title, mi.production_year, mi.keywords, mi.companies, mi.actors, mi.era
ORDER BY 
    mi.production_year DESC, actor_count DESC;
