WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.title, t.production_year
),
company_movie_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cmc.company_count,
    coalesce(rm.cast_count * cmc.company_count, 0) AS performance_metric,
    (SELECT AVG(mi.info::float) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.production_year 
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')) AS avg_budget
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movie_counts cmc ON rm.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id)
WHERE 
    rm.year_rank <= 5
ORDER BY 
    performance_metric DESC,
    rm.production_year DESC
LIMIT 10;
