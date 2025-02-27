
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        m.kind_id
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
complete_movie_info AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.cast_names,
        md.keywords,
        cd.company_names,
        cd.company_types
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    cm.movie_id,
    cm.movie_title,
    cm.production_year,
    cm.cast_names,
    cm.keywords,
    COALESCE(cm.company_names, 'Independent') AS company_names,
    COALESCE(cm.company_types, 'N/A') AS company_types
FROM 
    complete_movie_info cm
WHERE 
    cm.production_year >= 2000 
    AND cm.keywords LIKE '%Action%'
ORDER BY 
    cm.production_year DESC, 
    cm.movie_title;
