WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS row_num
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name a ON a.person_id = (
            SELECT 
                c.person_id 
            FROM 
                cast_info c 
            WHERE 
                c.movie_id = t.id 
            ORDER BY 
                c.nr_order 
            LIMIT 1
        )
    WHERE 
        t.production_year IS NOT NULL
    AND 
        k.keyword LIKE '%Drama%'
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT CASE WHEN a.name IS NULL THEN 1 END) AS null_actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mc.actors, 'No Cast Found') AS lead_actors,
    COALESCE(mc.null_actor_count, 0) AS missing_actor_count
FROM 
    ranked_movies r
LEFT JOIN 
    movie_cast mc ON r.movie_id = mc.movie_id
WHERE 
    r.row_num <= 5
ORDER BY 
    r.production_year DESC, 
    r.title;

This SQL query performs the following tasks:
1. It constructs a Common Table Expression (CTE) named `ranked_movies` that generates a list of movies sorted by year and names.
2. A subquery within this CTE fetches a leading actor by their order of appearance for each movie, ensuring some level of complexity with correlated subqueries.
3. Another CTE named `movie_cast` aggregates actor names for each movie using `STRING_AGG`, counting potential NULL values, showcasing NULL logic.
4. The final selection merges the ranked movie data with aggregated cast information and applies filtering.
5. The results include the top five movies per year, along with the lead actors, and handles NULLs gracefully.
