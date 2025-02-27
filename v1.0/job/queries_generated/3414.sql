WITH movie_rankings AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
company_counts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    mr.title,
    mr.production_year,
    COALESCE(mr.cast_count, 0) AS total_cast,
    COALESCE(cc.company_count, 0) AS total_companies,
    CASE 
        WHEN mr.year_rank <= 5 THEN 'Top 5'
        ELSE 'Not Top 5'
    END AS ranking_category
FROM 
    movie_rankings mr
FULL OUTER JOIN 
    company_counts cc ON mr.production_year = cc.movie_id
WHERE 
    mr.production_year IS NOT NULL
AND 
    (cc.company_count IS NULL OR cc.company_count > 0)
ORDER BY 
    mr.production_year DESC, mr.cast_count DESC
LIMIT 50;
