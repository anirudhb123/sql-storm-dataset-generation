WITH ranked_titles AS (
    SELECT 
        t.id AS title_id, 
        t.title AS title_name, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
),
cast_aggregation AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_name,
    rt.production_year,
    ca.total_cast,
    ca.cast_names,
    mis.info_details,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present_ratio
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_aggregation ca ON rt.title_id = ca.movie_id
LEFT JOIN 
    movie_info_summary mis ON rt.title_id = mis.movie_id
LEFT JOIN 
    movie_keyword mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    complete_cast c ON rt.title_id = c.movie_id
WHERE 
    rt.rank = 1 
    AND rt.production_year > 2000
GROUP BY 
    rt.title_name, rt.production_year, ca.total_cast, ca.cast_names, mis.info_details
ORDER BY 
    rt.production_year DESC, rt.title_name
LIMIT 50;
