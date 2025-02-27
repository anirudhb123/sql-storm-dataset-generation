WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        COUNT(*) AS role_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title kt ON ci.movie_id = kt.movie_id
    GROUP BY 
        ka.name, kt.title, kt.production_year
),
movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS summary_info,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS detail_info
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rt.title,
    rt.production_year,
    am.actor_name,
    am.role_count,
    mis.summary_info,
    mis.detail_info
FROM 
    ranked_titles rt
LEFT JOIN 
    actor_movies am ON rt.title = am.movie_title AND rt.production_year = am.production_year
LEFT JOIN 
    movie_info_summary mis ON rt.title_id = mis.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    am.role_count DESC NULLS LAST;
