WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        c.kind AS role_name
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword IS NOT NULL
),
aggregated_movies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year, kind_id
)
SELECT 
    am.movie_title,
    am.production_year,
    kt.kind AS kind_name,
    am.keywords,
    am.actors,
    am.actor_count
FROM 
    aggregated_movies am
JOIN 
    kind_type kt ON am.kind_id = kt.id
WHERE 
    am.actor_count > 5
ORDER BY 
    am.production_year DESC, am.actor_count DESC;

This SQL query performs a string processing benchmark by:

1. Selecting movie titles, production years, keywords, and actors from the `aka_title`, `keyword`, `cast_info`, and `aka_name` tables for movies produced after the year 2000.
2. Aggregating results to count distinct actors and combine keywords and actors into single strings using `STRING_AGG`.
3. Filtering the results to include only movies with more than 5 distinct actors.
4. Joining with the `kind_type` table to obtain the kind name, and ordering the results by production year and actor count.
