
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieSummary AS (
    SELECT 
        tt.title_id,
        tt.title,
        tt.production_year,
        COALESCE(cd.actor_count, 0) AS actor_count,
        cd.actor_names,
        COALESCE(cn.company_names, 'No companies') AS company_names
    FROM 
        RankedTitles tt
    LEFT JOIN 
        CastDetails cd ON tt.title_id = cd.movie_id
    LEFT JOIN 
        CompanyDetails cn ON tt.title_id = cn.movie_id
)
SELECT 
    ms.title_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.actor_names,
    ms.company_names
FROM 
    MovieSummary ms
WHERE 
    ms.actor_count > 0
ORDER BY 
    ms.production_year DESC, ms.title ASC
LIMIT 50;
