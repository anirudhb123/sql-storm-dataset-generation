WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%') 
        AND t.production_year IS NOT NULL
),
PersonRole AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
MoviesWithCompanyInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    mw.title,
    mw.production_year,
    pr.actor_name,
    pr.role,
    NULLIF(pr.actor_rank, 0) AS actor_display_rank,
    CASE 
        WHEN mw.company_name = 'Unknown Company' THEN 'No known production company'
        ELSE mw.company_name
    END AS company_info
FROM 
    MoviesWithCompanyInfo mw
LEFT JOIN 
    PersonRole pr ON mw.movie_id = pr.movie_id
WHERE 
    mw.rank_per_year <= 5
    AND (pr.actor_rank IS NULL OR pr.role IS NOT NULL)
ORDER BY 
    mw.production_year DESC, 
    mw.title,
    pr.actor_rank;

