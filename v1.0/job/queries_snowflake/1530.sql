
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
DetailedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(mc.total_companies, 0) AS company_count,
    COUNT(dc.actor_name) AS actor_count,
    LISTAGG(DISTINCT dc.actor_name, ', ') AS actors_list
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
LEFT JOIN 
    DetailedCast dc ON rt.title_id = dc.movie_id
WHERE 
    rt.rank_year <= 3 
GROUP BY 
    rt.title, rt.production_year, mc.total_companies
ORDER BY 
    rt.production_year DESC, actor_count DESC
LIMIT 100;
