WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank_by_actors <= 10
),
top_companies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(DISTINCT cn.name) > 2
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    tc.company_count,
    CASE 
        WHEN tc.company_count IS NULL THEN 'No company information'
        ELSE 'Company count available'
    END AS company_info_status
FROM 
    filtered_movies fm
LEFT JOIN 
    top_companies tc ON fm.production_year = tc.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
