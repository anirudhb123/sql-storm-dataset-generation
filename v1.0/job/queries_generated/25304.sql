WITH MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(CAST(CAST(COUNT(DISTINCT ca.person_id) AS TEXT) AS varchar) || ' cast' || CASE WHEN COUNT(DISTINCT ca.person_id) > 1 THEN 's' ELSE '' END, '0 cast'), ''), 'No cast') AS cast_count,
        COALESCE(mk.keywords, 'No keywords') AS movie_keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, mk.keywords
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
),
FinalReport AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        COALESCE(cd.company_names, 'No companies') AS production_companies,
        COALESCE(cd.company_types, 'N/A') AS company_types,
        md.movie_keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
)

SELECT 
    title,
    production_year,
    cast_count,
    production_companies,
    company_types,
    movie_keywords
FROM 
    FinalReport
ORDER BY 
    production_year DESC, title;
