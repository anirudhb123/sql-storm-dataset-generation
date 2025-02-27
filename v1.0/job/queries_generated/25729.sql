WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cc.role) AS cast_roles,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        MAX(ci.nr_order) AS max_order
    FROM 
        title t
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type cc ON ci.person_role_id = cc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
), 
info_aggregates AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year
)
SELECT 
    da.movie_id,
    da.title,
    da.production_year,
    da.aka_names,
    da.cast_roles,
    da.production_companies,
    ia.info_count,
    ia.keyword_count,
    da.max_order
FROM 
    movie_details da
JOIN 
    info_aggregates ia ON da.movie_id = ia.movie_id
WHERE 
    da.production_year >= 2000 
ORDER BY 
    da.production_year DESC, 
    da.title;
