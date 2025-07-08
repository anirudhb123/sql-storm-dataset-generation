
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        c.id AS company_id,
        c.name,
        c.country_code,
        CASE 
            WHEN cc.kind IS NULL THEN 'UNKNOWN'
            ELSE cc.kind
        END AS company_type
    FROM 
        company_name c
    LEFT JOIN 
        company_type cc ON c.id = cc.id
),
DetailedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
RelevantMovies AS (
    SELECT 
        dt.movie_id,
        dt.actor_name,
        ct.name AS company_name,
        ct.country_code,
        CASE 
            WHEN ct.country_code IS NULL THEN 'No Country Info'
            ELSE ct.country_code
        END AS display_country_code
    FROM 
        DetailedCast dt
    LEFT JOIN 
        movie_companies mc ON dt.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyInfo ct ON mc.company_id = ct.company_id
    WHERE 
        dt.actor_rank <= 3
    ORDER BY 
        dt.movie_id, dt.actor_rank
)

SELECT 
    r.title_id,
    r.title,
    r.production_year,
    COUNT(DISTINCT rm.actor_name) AS num_actors,
    LISTAGG(DISTINCT rm.company_name, ', ') WITHIN GROUP (ORDER BY rm.company_name) AS companies,
    MAX(rm.display_country_code) AS country_info
FROM 
    RankedTitles r
LEFT JOIN 
    RelevantMovies rm ON r.title_id = rm.movie_id
GROUP BY 
    r.title_id, r.title, r.production_year
HAVING 
    COUNT(DISTINCT rm.actor_name) > 0 
    AND (
        r.production_year >= 2000 OR 
        MAX(rm.display_country_code) IS NOT NULL 
        OR COUNT(DISTINCT rm.company_name) > 1
    )
ORDER BY 
    r.production_year DESC, 
    num_actors DESC
LIMIT 100;
