WITH actor_movie_count AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
top_5_actors AS (
    SELECT 
        actor_name,
        movie_count
    FROM 
        actor_movie_count
    ORDER BY 
        movie_count DESC
    LIMIT 5
),
actor_movies AS (
    SELECT 
        ak.name AS actor_name,
        m.title AS movie_title,
        m.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.movie_id
    WHERE 
        ak.name IN (SELECT actor_name FROM top_5_actors)
),
movies_with_keywords AS (
    SELECT 
        m.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
),
final_report AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        mk.keywords
    FROM 
        actor_movies am
    JOIN 
        movies_with_keywords mk ON am.movie_title = mk.movie_title
)
SELECT 
    *
FROM 
    final_report
ORDER BY 
    actor_name, production_year DESC;
