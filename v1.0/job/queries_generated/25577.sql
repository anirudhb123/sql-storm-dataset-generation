WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        row_number() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorsAndRoles AS (
    SELECT 
        ca.movie_id,
        co.name AS company_name,
        ak.name AS actor_name,
        ro.role AS role_name,
        ca.nr_order
    FROM 
        cast_info ca
    JOIN
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        role_type ro ON ca.role_id = ro.id
    JOIN 
        movie_companies mc ON ca.movie_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        string_agg(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.role_name,
    mi.movie_info
FROM 
    RankedTitles rt
JOIN 
    ActorsAndRoles ar ON rt.title_id = ar.movie_id
LEFT JOIN 
    MovieInfoDetails mi ON ar.movie_id = mi.movie_id
WHERE 
    rt.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rt.production_year DESC, rt.title_rank, ar.nr_order;
