WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_data AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
info_data AS (
    SELECT 
        mi.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(it.info, ': ', mi.info)) AS movie_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    cd.company_name,
    cd.company_type,
    id.movie_info
FROM 
    movie_data md
LEFT JOIN 
    company_data cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_data id ON md.movie_id = id.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
