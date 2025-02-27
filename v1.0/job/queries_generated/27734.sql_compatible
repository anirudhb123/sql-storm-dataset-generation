
WITH movie_data AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_members
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast c ON a.id = c.movie_id
    LEFT JOIN 
        name p ON c.subject_id = p.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year
),
info_data AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS info_details
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
    md.keywords,
    md.company_types,
    md.companies,
    md.cast_members,
    COALESCE(id.info_details, 'No additional info') AS info_details
FROM 
    movie_data md
LEFT JOIN 
    info_data id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
