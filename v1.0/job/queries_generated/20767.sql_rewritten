WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ca.subject_id, -1) AS subject_id,
        COUNT(DISTINCT co.name) AS company_count,
        SUM(CASE WHEN m.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast ca ON ca.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        movie_info m ON m.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year > 1900
    GROUP BY 
        t.title, t.production_year, ca.subject_id
),
ranked_movies AS (
    SELECT 
        *,
        MAX(company_count) OVER () AS max_company_count
    FROM 
        movie_data
)

SELECT 
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.year_rank,
    CASE 
        WHEN rm.company_count = rm.max_company_count THEN 'Top Company Count'
        ELSE 'Regular Movie'
    END AS category,
    (SELECT STRING_AGG(DISTINCT m.keyword, ', ')
     FROM movie_keyword mk
     JOIN keyword m ON m.id = mk.keyword_id
     WHERE mk.movie_id = rm.subject_id) AS keywords
FROM 
    ranked_movies rm
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC,
    rm.title
LIMIT 10;