WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
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
    md.role_ids,
    md.cast_count,
    kc.keyword_count,
    co.company_names,
    co.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
LEFT JOIN 
    CompanyDetails co ON md.movie_id = co.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
