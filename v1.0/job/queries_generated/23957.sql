WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        p.gender,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_order,
        COUNT(c.movie_id) OVER (PARTITION BY t.id) AS total_actors
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        name p ON a.person_id = p.id
    WHERE 
        t.production_year IS NOT NULL
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

selected_movies AS (
    SELECT 
        DISTINCT md.movie_title,
        md.production_year,
        md.actor_name,
        md.gender,
        md.actor_order,
        md.total_actors,
        COALESCE(mk.keywords_list, 'No Keywords') AS keywords_list
    FROM 
        movie_details md
    LEFT JOIN 
        movie_keywords mk ON md.production_year = mk.movie_id
    WHERE 
        md.total_actors >= 2
        AND (md.production_year BETWEEN 2000 AND 2023)
),

ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        gender,
        actor_order,
        keywords_list,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_order) AS rank_within_year
    FROM 
        selected_movies
)

SELECT 
    rm.production_year,
    STRING_AGG(rm.movie_title, '; ') AS movies,
    STRING_AGG(DISTINCT rm.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT rm.keywords_list, '; ') AS keywords,
    COUNT(*) AS total_movies
FROM 
    ranked_movies rm
WHERE 
    rm.rank_within_year <= 3
GROUP BY 
    rm.production_year
ORDER BY 
    rm.production_year DESC;

This SQL query performs a comprehensive analysis on movies and their actors from the provided schema. It includes the use of Common Table Expressions (CTEs) for organizing data, window functions for ranking actors within each production year, and multiple joins to enrich the dataset with relevant information about actors and keywords. The query captures the top three movies with the most actors for each production year while handling edge cases such as missing keywords and filtering based on production years.
