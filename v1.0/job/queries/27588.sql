WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t 
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS movie_info
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
    md.kind_id,
    md.cast_names,
    cd.company_names,
    cd.company_types,
    id.movie_info
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
