WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT cp.kind ORDER BY cp.kind SEPARATOR ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type cp ON mc.company_type_id = cp.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
info_summary AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT it.info ORDER BY it.info SEPARATOR '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_names,
    md.movie_keyword,
    is.info_details,
    COUNT(cc.id) AS complete_cast_count 
FROM 
    movie_details md
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    info_summary is ON md.movie_id = is.movie_id
WHERE 
    md.production_year > 2000
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_names, md.movie_keyword, is.info_details
ORDER BY 
    md.production_year DESC, md.title;
