WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(ci.id) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, a.name, r.role
),
CompanyInfo AS (
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
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    c.actor_name,
    c.role_name,
    co.company_name,
    co.company_type,
    k.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails c ON rt.title_id = c.movie_id
LEFT JOIN 
    CompanyInfo co ON rt.title_id = co.movie_id
LEFT JOIN 
    MovieKeywords k ON rt.title_id = k.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
