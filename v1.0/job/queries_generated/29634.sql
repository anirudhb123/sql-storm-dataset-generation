WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
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
        t.production_year >= 2000 -- Focusing on modern movies
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
    ARRAY_LENGTH(production_years, 1) AS year_span,
    all_keywords
FROM 
    ActorStatistics
ORDER BY 
    total_movies DESC
LIMIT 10;

This SQL query performs the following actions:

1. It creates a Common Table Expression (CTE) named `MovieDetails` that aggregates information about movies made after the year 2000, including titles, production years, actor names, their genders, and associated keywords.

2. It then computes statistics in another CTE named `ActorStatistics`, which collects total and unique movie counts for each actor, lists the production years of their films, and aggregates all keywords associated with the movies.

3. Finally, it selects the top 10 actors based on the total movie count, showing their statistics, including the span of production years (number of distinct years) and the aggregated keywords. The result set is ordered by total movies in descending order.
