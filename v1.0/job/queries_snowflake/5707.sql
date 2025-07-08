WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        p.gender AS actor_gender
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword ILIKE '%action%'
),
ActorSummary AS (
    SELECT 
        actor_name,
        actor_gender,
        COUNT(movie_title) AS movie_count,
        ARRAY_AGG(DISTINCT movie_title) AS movies
    FROM 
        MovieDetails
    GROUP BY 
        actor_name, actor_gender
)
SELECT 
    actor_name,
    actor_gender,
    movie_count,
    movies
FROM 
    ActorSummary
WHERE 
    movie_count > 5
ORDER BY 
    movie_count DESC;
