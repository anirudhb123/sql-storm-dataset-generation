WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS year_rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    GROUP BY 
        t.id
), 
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name, r.role
), 
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT i.info, '; ') AS movie_infos
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.company_count,
    ar.actor_name,
    ar.role_name,
    ar.movie_count,
    mi.keywords,
    mi.movie_infos
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id IN (SELECT a.person_id FROM aka_name a WHERE a.name = ar.actor_name))
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.year_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    rt.company_count DESC, 
    ar.movie_count DESC;
