WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
info_summary AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_list
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.cast_names,
    cd.company_name,
    cd.company_type,
    is.info_type_count,
    is.info_list
FROM 
    movie_details md
LEFT JOIN company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN info_summary is ON md.movie_id = is.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, COUNT(cd.company_name) DESC;
