WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY mc.id) AS company_order
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    cd.actor_name,
    COALESCE(cd.actor_order, 0) AS actor_order,
    ci.company_name,
    COALESCE(ci.company_order, 0) AS company_order
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE 
    rt.rank_year = 1
ORDER BY 
    rt.production_year DESC, rt.title, cd.actor_order, ci.company_order;
