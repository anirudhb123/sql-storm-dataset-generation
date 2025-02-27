WITH RankedTitles AS (
    SELECT 
        t.title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.movie_id, mt.company_id, c.name, ct.kind
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role_name,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
)
SELECT 
    rt.title,
    rt.production_year,
    md.company_name,
    md.company_type,
    cr.role_name,
    cr.total_cast
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
LEFT JOIN 
    CastRoles cr ON rt.title_id = cr.movie_id
WHERE 
    rt.rn <= 5
ORDER BY 
    rt.production_year DESC, 
    cr.total_cast DESC NULLS LAST
LIMIT 50;
