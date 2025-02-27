WITH movie_details AS (
    SELECT 
        a.title,
        a.production_year,
        b.name AS director_name,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(mk.id IS NOT NULL)::int AS keyword_count
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name b ON mc.company_id = b.id AND mc.company_type_id = 1
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    WHERE a.production_year >= 2000
    GROUP BY a.title, a.production_year, b.name
),
ranked_movies AS (
    SELECT 
        title,
        production_year,
        director_name,
        actor_count,
        keyword_count,
        RANK() OVER (PARTITION BY director_name ORDER BY actor_count DESC, keyword_count ASC) AS rank
    FROM movie_details
),
filtered_movies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 5 THEN 'High'
            WHEN actor_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS actor_density
    FROM ranked_movies
)
SELECT 
    director_name,
    COUNT(*) AS total_movies,
    AVG(actor_count) AS avg_actor_count,
    SUM(CASE WHEN actor_density = 'High' THEN 1 ELSE 0 END) AS high_density_count
FROM filtered_movies
WHERE rank <= 10
GROUP BY director_name
ORDER BY total_movies DESC;
