WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        ranked_movies 
    WHERE 
        role_count_rank <= 5
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        AVG(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS info_availability_percentage
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    GROUP BY 
        tm.title, tm.production_year
),
final_output AS (
    SELECT 
        md.title, 
        md.production_year,
        COALESCE(md.company_names, 'No Companies') AS company_names,
        ROUND(md.info_availability_percentage, 2) AS info_availability_percentage
    FROM 
        movie_details md
)

SELECT 
    fo.title,
    fo.production_year,
    fo.company_names,
    CASE 
        WHEN fo.info_availability_percentage IS NULL THEN 'No Data Available'
        ELSE CONCAT(fo.info_availability_percentage, '% Information Availability')
    END AS info_availability_status
FROM 
    final_output fo
ORDER BY 
    fo.production_year DESC, fo.title;
