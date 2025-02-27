
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, a.name, p.gender, t.production_year
),
ActorStatistics AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        COUNT(DISTINCT movie_title) AS unique_movies,
        ARRAY_AGG(DISTINCT production_year) AS production_years,
        STRING_AGG(DISTINCT keywords, ', ') AS all_keywords
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    total_movies,
    unique_movies,
    CARDINALITY(production_years) AS year_span,
    all_keywords
FROM 
    ActorStatistics
ORDER BY 
    total_movies DESC
LIMIT 10;
