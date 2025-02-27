WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(c.role_id, -1) AS role_id,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type c ON ci.role_id = c.id
    GROUP BY 
        a.person_id, a.name, c.role_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    mc.company_names,
    mc.company_types,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id 
       AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')) AS budget_info_count,
    CASE 
        WHEN ad.movie_count > 5 THEN 'Frequent Actor'
        WHEN ad.movie_count IS NULL THEN 'No Movies'
        ELSE 'Occasional Actor'
    END AS actor_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON ad.movie_count > 0
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rm.movie_id
WHERE 
    rm.rn <= 10
  AND 
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = rm.movie_id 
       AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword = 'Action') 
       AND mk.id IS NOT NULL) > 0
ORDER BY 
    rm.production_year DESC,
    ad.movie_count DESC
LIMIT 50;
