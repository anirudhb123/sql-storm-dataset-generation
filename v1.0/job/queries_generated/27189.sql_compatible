
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(cp.name, 'Unknown') AS company_name,
        COALESCE(a.name, 'Unknown') AS actor_name
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cp ON mc.company_id = cp.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, cp.name, a.name
), ActorStatistics AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_id) AS total_movies,
        COUNT(DISTINCT production_year) AS unique_years,
        STRING_AGG(DISTINCT title, ', ') AS movie_titles
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
), FinalResult AS (
    SELECT 
        COUNT(*) AS total_actors,
        AVG(total_movies) AS avg_movies_per_actor,
        MAX(unique_years) AS most_prolific_actor_years,
        MIN(unique_years) AS least_prolific_actor_years
    FROM 
        ActorStatistics
)

SELECT 
    fa.total_actors,
    fa.avg_movies_per_actor,
    fa.most_prolific_actor_years,
    fa.least_prolific_actor_years,
    (SELECT STRING_AGG(actor_name, ', ') FROM ActorStatistics WHERE total_movies >= (SELECT AVG(total_movies) FROM ActorStatistics)) AS prolific_actors
FROM 
    FinalResult fa;
