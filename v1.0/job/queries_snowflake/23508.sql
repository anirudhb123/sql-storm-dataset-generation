
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
cast_role_summary AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS unique_cast_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'Box Office' THEN mi.info END) AS box_office
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    cs.unique_cast_count,
    cs.roles,
    COALESCE(mis.budget, 'Unknown') AS budget,
    COALESCE(mis.box_office, 'Unknown') AS box_office,
    ks.keyword_count,
    CASE 
        WHEN ks.keyword_count > 0 THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_role_summary cs ON rt.title_id = cs.movie_id
LEFT JOIN 
    movie_info_summary mis ON rt.title_id = mis.movie_id
LEFT JOIN 
    keyword_summary ks ON rt.title_id = ks.movie_id
WHERE 
    rt.title_rank <= 3 
    AND (mis.budget IS NOT NULL OR mis.box_office IS NOT NULL) 
ORDER BY 
    rt.production_year DESC,
    ks.keyword_count DESC NULLS LAST;
