WITH ranked_titles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS title_count
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(CONCAT(an.name, ' as ', rt.role), ', ') AS cast_list,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
movie_info_details AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        MAX(mi.info) as latest_info
    FROM 
        movie_info mi
    JOIN 
        complete_cast cc ON mi.movie_id = cc.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = cc.movie_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.cast_list,
    cd.num_cast_members,
    mid.info_count,
    mid.latest_info,
    CASE 
        WHEN mid.info_count > 3 THEN 'Rich Info'
        WHEN mid.info_count IS NULL THEN 'No Info'
        ELSE 'Limited Info'
    END AS info_quality
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    movie_info_details mid ON rt.title_id = mid.movie_id
WHERE 
    rt.year_rank <= 5 AND 
    COALESCE(cd.num_cast_members, 0) > 2
ORDER BY 
    rt.production_year DESC, 
    info_quality, 
    rt.title
FETCH FIRST 10 ROWS ONLY;

