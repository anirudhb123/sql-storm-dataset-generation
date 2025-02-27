
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(cc.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
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
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.cast_count,
    cd.company_names,
    cd.company_types
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
