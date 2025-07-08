WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ai.name AS actor_name,
        kc.keyword AS keyword
    FROM 
        RankedTitles rt
    JOIN 
        movie_keyword mk ON mk.movie_id = rt.title_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    JOIN 
        complete_cast cc ON cc.movie_id = rt.title_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ai ON ai.person_id = ci.person_id
    WHERE 
        rt.year_rank <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tr.title,
    tr.production_year,
    tr.actor_name,
    tr.keyword,
    cd.company_name,
    cd.company_type
FROM 
    TopRatedTitles tr
LEFT JOIN 
    CompanyDetails cd ON tr.title_id = cd.movie_id
ORDER BY 
    tr.production_year DESC, tr.title;
