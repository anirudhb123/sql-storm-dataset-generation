WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS movie_kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        kind_type kt ON t.kind_id = kt.id
    GROUP BY 
        t.id, kt.kind
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        json_agg(DISTINCT json_build_object('type', ct.kind, 'country', cn.country_code)) AS companies_info
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
    md.movie_kind,
    md.cast_count,
    cd.company_names,
    cd.companies_info,
    md.keyword_count,
    md.year_rank,
    COALESCE(md.year_rank, 999) AS rank_check
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    (md.production_year >= 1990 OR md.movie_kind IS NOT NULL)
    AND (md.cast_count > 5 OR cd.company_names IS NOT NULL)
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 100;
