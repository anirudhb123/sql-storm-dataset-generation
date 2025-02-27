WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
actor_names AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        COUNT(*) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name, ci.movie_id
),
high_actor_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.actor_count > (
            SELECT 
                AVG(actor_count) FROM ranked_movies
        )
)
SELECT 
    ham.title,
    ham.production_year,
    ham.actor_count,
    COALESCE(an.movie_count, 0) AS number_of_movies_with_actor_name
FROM 
    high_actor_movies ham
LEFT JOIN 
    actor_names an ON ham.title = (
        SELECT 
            at.title 
        FROM 
            aka_title at
        LEFT JOIN 
            movie_info mi ON at.id = mi.movie_id 
        WHERE 
            mi.info LIKE '%actor%'
            AND mi.note IS NOT NULL
        LIMIT 1
    )
WHERE 
    ham.actor_count IS NOT NULL
ORDER BY 
    ham.production_year DESC,
    ham.actor_count DESC;
This query combines various SQL constructs to provide an overview of high-actor count movies while investigating actor names present in the titles containing "actor" in their movie info. It utilizes Common Table Expressions (CTEs) for structuring the query, applies window functions for ranking movies by actor count, and employs outer joins along with correlated subqueries. It also incorporates NULL handling and a COUNT aggregation across multiple levels, yielding a comprehensive performance benchmark.
