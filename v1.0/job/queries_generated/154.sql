WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(SUM(mc.company_id), 0) AS company_count,
        COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = m.id), 0) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.keyword_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Old'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'New'
    END AS age_category
FROM 
    movie_details md
JOIN 
    ranked_movies rm ON md.title = rm.title AND md.production_year = rm.production_year
WHERE 
    rm.rank <= 5
ORDER BY 
    md.production_year DESC, md.title;
