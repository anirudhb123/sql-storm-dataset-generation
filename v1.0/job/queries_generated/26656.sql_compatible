
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT c.role_id::TEXT, ',') AS role_ids,
        STRING_AGG(DISTINCT p.name, ',') AS cast_names
    FROM 
        aka_title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
keyword_details AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ',') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ',') AS additional_info
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
    md.role_ids,
    md.cast_names,
    kd.keywords,
    cd.companies,
    id.additional_info
FROM 
    movie_details md
LEFT JOIN 
    keyword_details kd ON md.movie_id = kd.movie_id
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
