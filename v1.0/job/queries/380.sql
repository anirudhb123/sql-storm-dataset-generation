WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COALESCE(cd.companies, 'No Companies') AS companies,
    COALESCE(cd.distributor_count, 0) AS distributor_count,
    COALESCE(ks.keyword_count, 0) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeywordStats ks ON md.movie_id = ks.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
