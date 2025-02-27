WITH movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
), 
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_list
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT(an.name, ' as ', rt.role), ', ') AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    t.id AS movie_id,
    t.title,
    t.production_year,
    kc.keyword_count,
    ci.cast_list,
    mid.info_list
FROM 
    title t
LEFT JOIN 
    movie_keyword_count kc ON t.id = kc.movie_id
LEFT JOIN 
    cast_summary ci ON t.id = ci.movie_id
LEFT JOIN 
    movie_info_details mid ON t.id = mid.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title;
