WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCredits AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastDetails AS (
    SELECT 
        ca.movie_id, 
        ak.name AS actor_name, 
        rt.role AS role_name
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        role_type rt ON ca.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    COALESCE(cc.company_name, 'Independent') AS company_name,
    COALESCE(cd.actor_name, 'Unknown Actor') AS lead_actor,
    MK.keywords,
    COUNT(cd.actor_name) AS total_actors,
    AVG(CASE WHEN cd.role_name = 'lead' THEN 1 ELSE 0 END) OVER (PARTITION BY rt.movie_id) AS lead_actor_percentage
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyCredits cc ON rt.title = cc.movie_id
LEFT JOIN 
    CastDetails cd ON rt.title = cd.movie_id
LEFT JOIN 
    MovieKeywords MK ON rt.title = MK.movie_id
WHERE 
    rt.rank <= 3
GROUP BY 
    rt.title, rt.production_year, cc.company_name, cd.actor_name, MK.keywords
ORDER BY 
    rt.production_year DESC, rt.title ASC;
