WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT movie_id FROM aka_title WHERE title = rm.title LIMIT 1) AND mi.info_type_id = 1) AS info_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.actor_count_rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.info_count, 0) AS info_count,
    COALESCE(ak.name, 'Unknown') AS lead_actor
FROM 
    filtered_movies fm
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = fm.title LIMIT 1) AND ci.nr_order = 1
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    fm.production_year IS NOT NULL
ORDER BY 
    fm.production_year DESC, info_count DESC;
