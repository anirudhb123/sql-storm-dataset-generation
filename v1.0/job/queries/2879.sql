WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.imdb_id DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
), 
ActorNames AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(a.name, 'Unknown Actor') AS lead_actor,
    ci.company_names,
    ci.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorNames a ON rt.title_id = a.movie_id AND a.actor_order = 1
LEFT JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE 
    rt.rn <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
