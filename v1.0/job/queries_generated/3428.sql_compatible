
WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS production_company_count,
        COUNT(DISTINCT mkw.keyword_id) AS keyword_count
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mkw ON m.id = mkw.movie_id
    GROUP BY 
        m.id, m.title
),
top_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_company_count,
        md.keyword_count,
        DENSE_RANK() OVER (ORDER BY md.production_company_count DESC, md.keyword_count DESC) AS rank
    FROM 
        movie_details md
    WHERE 
        md.production_company_count > 0
)
SELECT 
    t.title, 
    t.production_year, 
    COALESCE(c.name, 'Unknown') AS company_name,
    CASE 
        WHEN t.year_rank <= 3 THEN 'Top Recent Titles'
        ELSE 'Other Titles'
    END AS title_category
FROM 
    ranked_titles t
LEFT JOIN 
    movie_companies mc ON t.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    top_movies tm ON t.title_id = tm.movie_id
WHERE 
    c.country_code IS NULL OR c.country_code != 'US'
ORDER BY 
    t.production_year DESC, 
    tm.rank;
