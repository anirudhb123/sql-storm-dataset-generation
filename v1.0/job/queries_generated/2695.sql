WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
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
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(md.cast_count, 0) AS cast_member_count,
        COALESCE(cd.companies, 'No Companies') AS production_companies,
        COALESCE(cd.company_types, 'No Company Types') AS production_company_types,
        COALESCE(kd.keywords, 'No Keywords') AS movie_keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
    WHERE 
        md.production_year >= 2000
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_member_count DESC) AS rank_by_cast_size
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_member_count DESC;
