WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind) AS company_types,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id,
        m.title,
        m.production_year
),
ProductionCounts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT company_id) AS company_count,
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
    pc.company_count,
    pc.actor_count,
    md.actors,
    md.company_types,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    ProductionCounts pc ON md.movie_id = pc.movie_id
ORDER BY 
    md.production_year DESC, 
    pc.actor_count DESC
LIMIT 50;
