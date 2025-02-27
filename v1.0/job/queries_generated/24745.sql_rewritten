WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, '; ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'N/A') AS cast_names,
    COALESCE(comp.companies, 'No company info') AS companies,
    COALESCE(comp.company_types, 'No type info') AS company_types,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id) AS info_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Old'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'New'
    END AS movie_age_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails comp ON rm.movie_id = comp.movie_id
WHERE 
    rm.title_rank <= 10
ORDER BY 
    rm.production_year DESC,
    rm.title ASC;