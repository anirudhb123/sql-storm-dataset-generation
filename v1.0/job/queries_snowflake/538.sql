WITH ranked_movies AS (
    SELECT 
        at.title, 
        at.production_year, 
        tk.kind AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS count_per_year
    FROM 
        aka_title at
    JOIN 
        kind_type tk ON at.kind_id = tk.id
    WHERE 
        at.production_year IS NOT NULL
    ),
actor_movie_info AS (
    SELECT 
        ak.name AS actor_name, 
        rm.title AS movie_title, 
        rm.production_year,
        COUNT(DISTINCT ci.person_role_id) AS role_count
    FROM 
        ranked_movies rm
    JOIN 
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name, rm.title, rm.production_year
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
)
SELECT 
    ami.actor_name, 
    ami.movie_title, 
    ami.production_year,
    ami.role_count,
    CASE 
        WHEN ami.role_count > 3 THEN 'High Performer'
        WHEN ami.role_count BETWEEN 2 AND 3 THEN 'Moderate Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM 
    actor_movie_info ami
WHERE 
    ami.production_year = (
        SELECT MAX(production_year) FROM ranked_movies
    )
ORDER BY 
    ami.role_count DESC, 
    ami.actor_name
LIMIT 10;
