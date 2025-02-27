
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type AS c ON mc.company_type_id = c.id 
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.title, t.production_year, a.name, a.id
),
ActorCount AS (
    SELECT 
        actor_id,
        COUNT(*) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_id
),
TopActors AS (
    SELECT 
        md.actor_name,
        ac.movie_count,
        md.keywords,
        md.company_types
    FROM 
        MovieDetails md
    JOIN 
        ActorCount ac ON md.actor_id = ac.actor_id
    ORDER BY 
        ac.movie_count DESC
    LIMIT 10 
)
SELECT 
    actor_name,
    movie_count,
    keywords,
    company_types
FROM 
    TopActors;
