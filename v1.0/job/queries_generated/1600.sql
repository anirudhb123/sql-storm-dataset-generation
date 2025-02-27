WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        cc.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS actor_movie_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    JOIN 
        comp_cast_type cc ON ci.person_role_id = cc.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    rt.production_year,
    rt.title,
    ar.actor_name,
    ar.role_type,
    cm.company_name,
    cm.company_type,
    cm.company_count,
    (SELECT 
        COUNT(*)
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = rt.movie_id AND 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_info_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title = ar.movie_title
LEFT JOIN 
    CompanyMovies cm ON cm.movie_id = rt.movie_id
WHERE 
    ar.actor_movie_rank <= 3
ORDER BY 
    rt.production_year DESC, rt.title;
