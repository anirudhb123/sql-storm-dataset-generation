
WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        aka_title a
    JOIN 
        cast_info ci ON ci.movie_id = a.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = a.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year, ak.name, ct.kind
), 
ActorSummary AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count,
        MIN(production_year) AS first_appearance,
        MAX(production_year) AS last_appearance
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)

SELECT 
    asum.actor_name,
    asum.movie_count,
    asum.first_appearance,
    asum.last_appearance,
    STRING_AGG(DISTINCT md.movie_title, ',') AS titles_featured,
    MAX(md.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT md.company_type, ',') AS associated_companies,
    STRING_AGG(DISTINCT md.keywords, ',') AS associated_keywords
FROM 
    ActorSummary asum
JOIN 
    MovieDetails md ON asum.actor_name = md.actor_name
GROUP BY 
    asum.actor_name, asum.movie_count, asum.first_appearance, asum.last_appearance
ORDER BY 
    asum.movie_count DESC, asum.actor_name;
