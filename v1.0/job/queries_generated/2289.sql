WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cs.company_count,
    cs.company_names,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id = rt.title_id) AS cast_count,
    COALESCE((SELECT AVG(CAST(mk.keyword AS FLOAT))
              FROM movie_keyword mk 
              WHERE mk.movie_id = rt.title_id), 0) AS avg_keyword_id
FROM 
    ranked_titles rt
LEFT JOIN 
    company_summary cs ON rt.title_id = cs.movie_id
WHERE 
    (rt.title_rank <= 5 OR cs.company_count > 3)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
