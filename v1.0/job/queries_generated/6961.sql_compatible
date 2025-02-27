
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        STRING_AGG(c.name, ', ') AS cast_names,
        STRING_AGG(cir.info, ', ') AS person_info
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        person_info cir ON c.person_id = cir.person_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
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
    md.keyword,
    md.cast_names,
    cd.company_names,
    cd.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
