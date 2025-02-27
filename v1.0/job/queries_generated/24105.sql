WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
company_role_count AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_cast_count,
        COUNT(DISTINCT cn.company_id) AS unique_company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
extended_movie_info AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS all_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
),
cast_with_roles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
final_benchmark AS (
    SELECT 
        rt.title,
        rt.production_year,
        COALESCE(cu.unique_cast_count, 0) AS unique_cast_count,
        COALESCE(cu.unique_company_count, 0) AS unique_company_count,
        e.all_info,
        ROW_NUMBER() OVER (ORDER BY rt.production_year DESC) AS year_rank
    FROM 
        ranked_titles rt
    LEFT JOIN 
        company_role_count cu ON rt.title_id = cu.movie_id
    LEFT JOIN 
        extended_movie_info e ON rt.title_id = e.movie_id
)

SELECT 
    title,
    production_year,
    unique_cast_count,
    unique_company_count,
    all_info,
    (CASE 
        WHEN unique_cast_count > 5 THEN 'Popular Cast'
        WHEN unique_cast_count IS NULL THEN 'No Cast Information'
        ELSE 'Standard Cast'
    END) AS cast_category,
    (CASE 
        WHEN production_year IS NOT NULL AND production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END) AS movie_epoch
FROM 
    final_benchmark
WHERE 
    title IS NOT NULL
ORDER BY 
    year_rank DESC, 
    title ASC
LIMIT 100 OFFSET 50;
