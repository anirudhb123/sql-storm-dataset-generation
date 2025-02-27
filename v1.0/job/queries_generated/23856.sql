WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) OVER (PARTITION BY at.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rn,
        ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.name IS NOT NULL) AS actor_names
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        at.production_year IS NOT NULL 
        AND at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.movie_id, at.title, at.production_year
),
filtered_movies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        actor_names
    FROM 
        ranked_movies
    WHERE 
        actor_count >= 5
)
SELECT 
    fm.production_year,
    fm.title,
    fm.actor_count,
    fm.actor_names,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
       AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword ~* 'action')
    ) AS action_keyword_count,
    COALESCE((SELECT COUNT(*)
               FROM movie_info mi
               JOIN info_type it ON mi.info_type_id = it.id
               WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = fm.title AND production_year = fm.production_year LIMIT 1)
                 AND it.info = 'box office'), 0) AS box_office_info_count
FROM 
    filtered_movies fm
WHERE 
    fm.production_year NOT IN (SELECT DISTINCT production_year FROM aka_title WHERE production_year IS NULL)
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC
FETCH FIRST 10 ROWS ONLY;
