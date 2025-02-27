WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(movie_info.info_type_id) AS avg_info_type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS companies_used
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.total_cast,
    cm.companies_used,
    rm.avg_info_type,
    CASE 
        WHEN cm.companies_used IS NULL THEN 'No Companies'
        WHEN cm.companies_used > 0 THEN 'Companies Present'
        ELSE 'Unknown'
    END AS company_status
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movies cm ON rm.movie_title = (
        SELECT title FROM aka_title WHERE id = cm.movie_id
    )
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.avg_info_type ASC, 
    rm.total_cast DESC;
