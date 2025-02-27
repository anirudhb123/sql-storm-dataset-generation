WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopTenTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 10
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CastInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    mc.company_names,
    ci.cast_names
FROM 
    TopTenTitles tt
LEFT JOIN 
    MovieCompanies mc ON tt.title_id = mc.movie_id
LEFT JOIN 
    CastInfo ci ON tt.title_id = ci.movie_id
ORDER BY 
    tt.production_year DESC, tt.title;