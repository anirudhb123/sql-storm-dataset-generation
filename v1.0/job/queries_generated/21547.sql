WITH eligible_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year >= 2000
        AND (k.keyword IS NULL OR k.keyword NOT LIKE '%action%')
),
cast_ranking AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
top_ranked_movies AS (
    SELECT 
        et.title_id,
        et.title,
        et.production_year,
        cr.total_cast
    FROM 
        eligible_titles et
    JOIN 
        cast_ranking cr ON et.title_id = cr.movie_id
    WHERE 
        cr.rank <= 5
),
average_production_year AS (
    SELECT 
        AVG(production_year) AS avg_year 
    FROM 
        title
    WHERE 
        production_year IS NOT NULL
),
company_multiple_titles AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS title_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 3
)
SELECT 
    TRIM(t.title) AS Movie_Title,
    t.production_year AS Production_Year,
    t.total_cast AS Total_Cast_Members,
    CASE 
        WHEN t.production_year < (SELECT avg_year FROM average_production_year) THEN 'Older than average'
        ELSE 'Newer than average'
    END AS Year_Comparison,
    CASE 
        WHEN cm.title_count IS NOT NULL THEN 'Multiple Titles'
        ELSE 'Single Title'
    END AS Company_Title_Status
FROM 
    top_ranked_movies t
LEFT JOIN 
    company_multiple_titles cm ON t.title_id = cm.company_id
WHERE 
    t.total_cast BETWEEN 5 AND 20
ORDER BY 
    t.production_year DESC NULLS LAST,
    t.total_cast DESC;
