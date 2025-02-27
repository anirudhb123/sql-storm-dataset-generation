WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        c.role_id,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword LIKE 'action%'
),
AggregateDetails AS (
    SELECT 
        movie_title,
        production_year,
        ARRAY_AGG(DISTINCT actor_name) AS actors,
        COUNT(DISTINCT actor_name) AS actor_count,
        ARRAY_AGG(DISTINCT keyword) AS keywords_used
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actor_count,
    STRING_AGG(DISTINCT actor_name, ', ') AS all_actors,
    STRING_AGG(DISTINCT keyword, ', ') AS all_keywords
FROM 
    AggregateDetails
GROUP BY 
    movie_title, production_year, actor_count
ORDER BY 
    production_year DESC, actor_count DESC;

This query first retrieves details of movies produced after the year 2000 that have keywords starting with "action". It joins several tables to gather movie titles, production years, actor names, role IDs, and associated keywords. Then, it aggregates these details to count distinct actors and collect distinct keywords for each movie title and production year. Finally, it selects this data while formatting the actor names and keywords into readable strings, ordered by the production year and actor count.
