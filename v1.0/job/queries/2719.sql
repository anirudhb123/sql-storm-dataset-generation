WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rn
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
actor_names AS (
    SELECT 
        aka_name.person_id,
        STRING_AGG(aka_name.name, ', ') AS all_names
    FROM 
        aka_name
    GROUP BY 
        aka_name.person_id
),
cast_details AS (
    SELECT 
        cast_info.movie_id,
        actor_names.all_names,
        COUNT(DISTINCT cast_info.role_id) AS role_count
    FROM 
        cast_info
    JOIN 
        actor_names ON cast_info.person_id = actor_names.person_id
    GROUP BY 
        cast_info.movie_id, actor_names.all_names
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    cd.all_names,
    cd.role_count,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director
FROM 
    ranked_titles rt
LEFT JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    cast_details cd ON cc.movie_id = cd.movie_id
LEFT JOIN 
    movie_companies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON rt.title_id = mi.movie_id AND mi.info_type_id IN (1, 2)
WHERE 
    rt.rn <= 10 AND
    rt.production_year >= 2000
GROUP BY 
    rt.title, rt.production_year, cd.all_names, cd.role_count
HAVING 
    COUNT(DISTINCT cd.all_names) > 1
ORDER BY 
    rt.production_year DESC, movie_title;
