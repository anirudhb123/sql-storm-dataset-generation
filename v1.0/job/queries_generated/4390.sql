WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        SUM(CASE WHEN ci.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS has_cast_info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actors,
        md.keyword_count,
        cd.companies,
        cd.company_types,
        RANK() OVER (ORDER BY md.production_year DESC, md.keyword_count DESC) AS movie_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_title = cd.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actors,
    rm.keyword_count,
    rm.companies,
    rm.company_types,
    COALESCE(rm.movie_rank, 0) AS movie_rank
FROM 
    RankedMovies rm
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
    AND (rm.company_types > 2 OR rm.keyword_count > 5)
ORDER BY 
    rm.movie_rank ASC
LIMIT 100;
