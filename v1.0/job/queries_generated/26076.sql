WITH movie_characteristics AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS movie_kind,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS total_cast
    FROM 
        title t
    JOIN 
        aka_title ak ON ak.movie_id = t.id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        kind_type c ON c.id = t.kind_id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
movie_info_data AS (
    SELECT
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_data
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx m ON m.movie_id = mi.movie_id 
    GROUP BY 
        m.movie_id
)

SELECT 
    mc.movie_title,
    mc.production_year,
    mc.movie_kind,
    mc.aka_names,
    mc.keywords,
    mc.company_names,
    mc.total_cast,
    mid.info_data
FROM 
    movie_characteristics mc
LEFT JOIN 
    movie_info_data mid ON mid.movie_id = mc.movie_title
WHERE 
    mc.production_year >= 1990 AND mc.total_cast >= 5
ORDER BY 
    mc.production_year DESC, mc.movie_title;
