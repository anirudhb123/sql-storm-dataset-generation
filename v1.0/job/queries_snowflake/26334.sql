
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
), 
ActorRoles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
), 
MovieInformation AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS movie_details
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.role_name,
    cm.company_name,
    cm.company_type,
    cm.company_count,
    mi.movie_details
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.actor_rank <= 3
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    MovieInformation mi ON rt.title_id = mi.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
