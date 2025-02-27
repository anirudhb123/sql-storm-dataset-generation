WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, k.keyword
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ac.movie_count, 0) AS actor_movie_count,
    COALESCE(ac.roles, 'None') AS actor_roles,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
    COALESCE(ci.companies, 'No Companies') AS movie_companies
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoleCounts ac ON ac.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id = rt.title_id
    )
LEFT JOIN 
    MoviesWithKeywords mk ON mk.movie_id = rt.title_id
LEFT JOIN 
    CompanyInfo ci ON ci.movie_id = rt.title_id
WHERE 
    rt.rn <= 10
ORDER BY 
    rt.production_year DESC, rt.title;
