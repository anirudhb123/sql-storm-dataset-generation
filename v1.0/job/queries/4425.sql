
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(COUNT(DISTINCT ca.person_id), 0) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), movie_info_details AS (
    SELECT 
        mi.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info END) AS budget_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COALESCE(mid.keyword_count, 0) AS keyword_count,
    mid.budget_info
FROM 
    movie_details md
LEFT JOIN 
    movie_info_details mid ON md.movie_id = mid.movie_id
ORDER BY 
    md.production_year DESC,
    md.total_cast DESC
LIMIT 100;
