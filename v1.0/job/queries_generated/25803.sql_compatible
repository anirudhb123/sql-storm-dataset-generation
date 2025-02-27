
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
), 
ProductionCompanies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ar.actor_name,
        ar.role_name,
        pc.company_name,
        pc.company_type
    FROM 
        RankedTitles rt
    LEFT JOIN 
        ActorRoles ar ON rt.title_id = ar.movie_id AND ar.role_rank = 1
    LEFT JOIN 
        ProductionCompanies pc ON rt.title_id = pc.movie_id AND pc.company_rank = 1
    WHERE 
        rt.keyword_rank = 1
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT role_name, ', ') AS roles,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', ', ') AS production_companies
FROM 
    MovieDetails
GROUP BY 
    title_id, title, production_year
ORDER BY 
    production_year DESC;
