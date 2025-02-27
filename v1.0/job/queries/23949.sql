WITH MovieYear AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(NULLIF(m.production_year, 2023), 2023) AS adjusted_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
), ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role AS actor_role,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), RankedActors AS (
    SELECT 
        ar.movie_id,
        ar.actor_role,
        ar.num_actors,
        RANK() OVER (PARTITION BY ar.movie_id ORDER BY ar.num_actors DESC) AS role_rank
    FROM 
        ActorRoles ar
), TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
), MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
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
    my.title,
    my.production_year,
    COALESCE(ra.actor_role, 'Unknown') AS role,
    COALESCE(ra.num_actors, 0) AS num_actors,
    tk.keywords,
    mi.companies,
    mi.company_types
FROM 
    MovieYear my
LEFT JOIN 
    RankedActors ra ON my.movie_id = ra.movie_id AND ra.role_rank = 1
LEFT JOIN 
    TitleKeywords tk ON my.movie_id = tk.movie_id
LEFT JOIN 
    MovieCompanyInfo mi ON my.movie_id = mi.movie_id
WHERE 
    my.adjusted_year < 2020
    AND (mi.companies IS NOT NULL OR ra.actor_role IS NULL)
ORDER BY 
    my.production_year DESC,
    num_actors DESC
LIMIT 100;

