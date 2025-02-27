WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(m.co_name, 'Unknown') AS company_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name m ON mc.company_id = m.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rn <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, company_name
),
final_result AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.keyword_count,
        md.cast_count,
        CASE 
            WHEN md.cast_count > 0 THEN 'Has Cast'
            ELSE 'No Cast'
        END AS cast_status
    FROM 
        movie_details md
)
SELECT 
    fr.*, 
    CONCAT('Movie: ', fr.title, ', Year: ', fr.production_year, ', Keywords: ', fr.keyword_count) AS movie_info
FROM 
    final_result fr
WHERE 
    fr.keyword_count > 1
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
