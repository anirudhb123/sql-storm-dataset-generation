WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.id) AS movie_count,
        GROUP_CONCAT(DISTINCT md.title) AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        MovieDetails md ON ci.movie_id = md.movie_id
    GROUP BY 
        a.name
)
SELECT 
    ai.actor_name,
    ai.movie_count,
    md.keywords,
    md.company_types
FROM 
    ActorInfo ai
JOIN 
    MovieDetails md ON ai.movies LIKE CONCAT('%', md.title, '%')
ORDER BY 
    ai.movie_count DESC, 
    md.production_year ASC 
LIMIT 50;
