
WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ct.kind AS role,
        ci.movie_id, 
        COUNT(*) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ct.kind, ci.movie_id
),
TitleWithCast AS (
    SELECT 
        at.id AS title_id,
        at.title,
        mt.companies,
        cd.role,
        cd.cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY cd.cast_count DESC) AS role_rank
    FROM 
        aka_title at
    LEFT JOIN 
        MovieCompanies mt ON at.id = mt.movie_id
    LEFT JOIN 
        CastDetails cd ON at.id = cd.movie_id
)
SELECT 
    twc.title,
    rt.production_year,
    twc.companies,
    twc.role,
    COALESCE(twc.cast_count, 0) AS cast_count,
    CASE 
        WHEN twc.role_rank IS NULL THEN 'No cast available'
        ELSE 'Has cast'
    END AS cast_status
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleWithCast twc ON rt.title = twc.title 
WHERE 
    rt.rank_year <= 5
GROUP BY 
    twc.title,
    rt.production_year,
    twc.companies,
    twc.role,
    twc.cast_count,
    twc.role_rank
ORDER BY 
    rt.production_year DESC,
    twc.cast_count DESC;
