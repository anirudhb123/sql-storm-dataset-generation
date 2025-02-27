WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        array_agg(DISTINCT ak.name) AS aka_names,
        array_agg(DISTINCT c.name) AS cast_names,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        array_agg(DISTINCT cn.name) AS companies,
        array_agg(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
info_details AS (
    SELECT 
        mi.movie_id,
        array_agg(DISTINCT it.info || ': ' || mi.info) AS movie_info
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
    md.aka_names,
    cd.companies,
    cd.company_types,
    id.movie_info
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
