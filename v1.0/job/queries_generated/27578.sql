WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS rn
    FROM 
        ActorMovies
    WHERE 
        production_year >= 2000
)

SELECT 
    f.actor_id,
    f.actor_name,
    CASE 
        WHEN f.rn = 1 THEN 'Latest Movie'
        ELSE 'Earlier Movie'
    END AS movie_type,
    f.movie_title,
    f.production_year,
    f.keywords
FROM 
    FilteredMovies f
WHERE 
    f.rn <= 3
ORDER BY 
    f.actor_id, f.production_year DESC;

This SQL query performs several operations to benchmark string processing by:

1. **Aggregating** actor names and their respective movies along with relevant keywords.
2. **Filtering** the results to include only those movies produced after the year 2000.
3. **Using a Common Table Expression (CTE)** that allows easy readability and maintenance of the query.
4. **Applying window functions** to provide additional context on which movie is the latest for each actor.
5. **Classifying movies** based on their recency for each actor, and including relevant keywords to add richness to the results.
6. **Presenting results in a structured format** that groups movie data with actor details efficiently for further analysis or benchmarking.
