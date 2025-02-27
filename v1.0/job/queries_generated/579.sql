WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT it.info, ', ') AS details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
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
)

SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    mi.details AS movie_details,
    cd.companies,
    cd.company_types
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieInfo mi ON rt.movie_title = mi.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.movie_title = cd.movie_id
WHERE 
    rt.rn = 1
    AND (cd.companies IS NOT NULL OR cd.company_types IS NOT NULL)
ORDER BY 
    rt.actor_name, rt.production_year DESC;
