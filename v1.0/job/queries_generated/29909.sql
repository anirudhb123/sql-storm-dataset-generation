WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year
    FROM
        RankedTitles rt
    WHERE 
        rt.title_rank <= 10
),
MoviesWithCompanies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        mt.production_year
    FROM 
        TopTitles tt
    JOIN 
        movie_companies mc ON tt.title_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    m.title,
    m.production_year,
    m.company_name,
    m.company_type,
    STRING_AGG(cd.actor_name, ', ' ORDER BY cd.nr_order) AS actors
FROM 
    MoviesWithCompanies m
LEFT JOIN 
    CastDetails cd ON m.movie_id = cd.movie_id
GROUP BY 
    m.title, m.production_year, m.company_name, m.company_type
ORDER BY 
    m.production_year DESC, LENGTH(m.title) DESC;
