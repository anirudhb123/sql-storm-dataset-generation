
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_titles
    FROM 
        aka_title a
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyTypes AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ar.role,
    ar.actor_count,
    mk.keywords,
    mct.company_types
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyTypes mct ON rt.movie_id = mct.movie_id
WHERE 
    rt.title_rank = 1
    AND (rt.production_year IS NOT NULL OR ar.actor_count IS NULL) 
    AND (mct.company_types <> 'None' OR mct.company_types IS NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
