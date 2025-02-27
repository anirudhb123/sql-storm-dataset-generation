WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ki.keyword, 'Unknown') AS keyword_used,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(pi.info_length) AS average_info_length
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        (SELECT 
             movie_id,
             LENGTH(info) AS info_length
         FROM 
             movie_info) pi ON rm.movie_id = pi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ki.keyword
),
cast_role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
final_summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword_used,
        md.company_count,
        md.average_info_length,
        crs.role,
        crs.role_count
    FROM 
        movie_details md
    LEFT JOIN 
        cast_role_summary crs ON md.movie_id = crs.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword_used,
    company_count,
    average_info_length,
    role,
    role_count
FROM 
    final_summary
WHERE 
    (production_year >= 2000 AND company_count > 2)
    OR (keyword_used IS NOT NULL AND role_count > 1)
ORDER BY 
    production_year DESC, role_count DESC;
