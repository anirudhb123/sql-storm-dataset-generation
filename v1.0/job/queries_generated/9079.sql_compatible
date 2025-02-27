
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),

ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    GROUP BY 
        a.id, a.name
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ad.name AS actor_name,
    ad.movies_count,
    ad.avg_production_year,
    md.keywords,
    md.companies
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    ActorDetails ad ON ci.person_id = ad.actor_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    ad.movies_count DESC;
