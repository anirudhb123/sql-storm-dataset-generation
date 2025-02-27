WITH RecursiveTitleCTE AS (
    SELECT 
        t.id, 
        t.title, 
        t.production_year, 
        t.kind_id,
        COALESCE(t2.title, 'N/A') AS parent_title
    FROM 
        title t
    LEFT JOIN 
        title t2 ON t.episode_of_id = t2.id

), CastRoleInfo AS (
    SELECT 
        ci.movie_id, 
        ci.role_id, 
        rt.role,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
), MovieDetails AS (
    SELECT 
        rt.id AS title_id,
        rt.title,
        rt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT nk.keyword, ', ') AS keywords,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info ELSE NULL END) AS genre,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info ELSE NULL END) AS summary
    FROM 
        RecursiveTitleCTE rt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = rt.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = rt.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rt.id
    LEFT JOIN 
        keyword nk ON mk.keyword_id = nk.id
    GROUP BY 
        rt.id, rt.title, rt.production_year
)

SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.keywords,
    md.genre,
    md.summary,
    cr.role,
    cr.role_order,
    COALESCE(NULLIF(md.summary, ''), 'No summary available') AS effective_summary
FROM 
    MovieDetails md
LEFT JOIN 
    CastRoleInfo cr ON cr.movie_id = md.title_id
WHERE
    md.production_year >= 2000
    AND md.total_cast > 5
ORDER BY 
    md.production_year DESC, 
    md.title;
