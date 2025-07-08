WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
CompanyDetails AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type
    FROM 
        company_name c
    JOIN 
        company_type ct ON c.id = ct.id
    WHERE 
        c.country_code = 'USA'
),
CastWithRoles AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS role_rank
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type r ON ca.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieInfoWithTitles AS (
    SELECT 
        mi.movie_id,
        mi.info,
        rt.title AS movie_title
    FROM 
        movie_info mi
    JOIN 
        RankedTitles rt ON mi.movie_id = rt.title_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.name AS company_name,
    cd.company_type,
    cwr.actor_name,
    cwr.role_name,
    mw.keyword
FROM 
    RankedTitles rt
JOIN 
    MovieInfoWithTitles mit ON rt.title_id = mit.movie_id
JOIN 
    CompanyDetails cd ON mit.movie_id = cd.company_id
JOIN 
    CastWithRoles cwr ON rt.title_id = cwr.movie_id
JOIN 
    MovieKeywords mw ON rt.title_id = mw.movie_id
WHERE 
    cwr.role_rank <= 3 
ORDER BY 
    rt.production_year DESC, rt.title;
