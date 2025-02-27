WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
selected_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast,
        COALESCE(mo.info, 'No info') AS movie_info
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mo ON rm.title = mo.info AND mo.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
    WHERE 
        rm.rank <= 10
)
SELECT 
    sm.title,
    sm.production_year,
    sm.num_cast,
    sm.movie_info,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'No alias') AS aliases
FROM 
    selected_movies sm
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = sm.title LIMIT 1))
GROUP BY 
    sm.title, sm.production_year, sm.num_cast, sm.movie_info
ORDER BY 
    sm.production_year DESC, sm.num_cast DESC;
