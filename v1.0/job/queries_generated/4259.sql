WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_infos
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.num_cast_members, 0) AS num_cast_members,
    COALESCE(md.cast_names, 'No Cast') AS cast_names,
    COALESCE(cd.companies, 'No Companies') AS companies,
    COALESCE(cd.company_types, 'No Types') AS company_types,
    COALESCE(mid.movie_infos, 'No Info') AS additional_info
FROM 
    MovieDetails md
FULL OUTER JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
FULL OUTER JOIN 
    MovieInfoDetails mid ON md.movie_id = mid.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
    OR cd.companies IS NOT NULL
ORDER BY 
    md.production_year DESC NULLS LAST, 
    md.title;
