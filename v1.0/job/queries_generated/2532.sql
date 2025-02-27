WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
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
    rt.title_id,
    rt.title,
    rt.production_year,
    cd.cast_count,
    cd.actors_names,
    COALESCE(mc.companies, 'No Companies') AS companies,
    COALESCE(mc.company_types, 'No Types') AS company_types
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    rt.year_rank <= 5 OR rt.production_year IS NULL
ORDER BY 
    rt.production_year DESC, rt.title;
