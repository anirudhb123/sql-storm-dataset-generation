WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ca.id AS cast_id,
        a.name AS actor_name,
        c.role_id,
        COUNT(*) OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS role_order,
        RANK() OVER (PARTITION BY ca.movie_id ORDER BY c.role_id) AS role_rank
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        role_type c ON ca.role_id = c.id
),
DistinctTitles AS (
    SELECT DISTINCT
        m.title AS title,
        m.id AS movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (
            SELECT id FROM kind_type WHERE kind IN ('movie', 'tv')
        )
),
CompaniesInfo AS (
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
)

SELECT 
    r.movie_title,
    r.production_year,
    a.actor_name,
    a.role_order,
    a.role_rank,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    (SELECT COUNT(DISTINCT k.keyword) FROM movie_keyword mk
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = r.movie_id) AS keyword_count,
    CASE 
        WHEN r.production_year < 2000 THEN 'Classic'
        WHEN r.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    STRING_AGG(DISTINCT ci.company_type, ', ') AS company_types
FROM 
    RankedMovies r
LEFT JOIN 
    ActorRoles a ON r.movie_id = a.cast_id 
LEFT JOIN 
    CompaniesInfo ci ON r.movie_id = ci.movie_id
WHERE 
    r.rn <= 10 
    AND (a.role_order IS NOT NULL OR a.role_rank IS NOT NULL)
GROUP BY 
    r.movie_id, r.movie_title, r.production_year, a.actor_name, a.role_order,
    a.role_rank, ci.company_name
ORDER BY 
    r.production_year DESC, r.movie_title;
