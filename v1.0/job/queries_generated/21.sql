WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(cc.id) AS total_cast,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    ci.company_name,
    ci.company_type,
    ci.total_companies,
    kd.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyInfo ci ON md.production_year = (SELECT MAX(m.production_year) FROM MovieDetails m WHERE m.total_cast > 5)
LEFT JOIN 
    KeywordDetails kd ON md.title = kd.movie_id
WHERE 
    md.total_cast IS NOT NULL
ORDER BY 
    md.production_year DESC, md.total_cast DESC
LIMIT 10;
