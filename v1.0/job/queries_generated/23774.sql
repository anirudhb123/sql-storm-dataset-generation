WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COALESCE(NULLIF(t.title, ''), 'Untitled') AS safe_title,
        CASE 
            WHEN t.production_year IS NULL THEN 'Unknown Year'
            WHEN t.production_year < 1900 THEN 'Pre-1900'
            ELSE 'Recent'
        END AS production_age
    FROM 
        title t
    WHERE
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        c.note AS role_note,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_companies
    FROM 
        movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.name AS actor_name,
    ar.role_note,
    cm.company_count,
    cm.production_companies,
    mk.keywords,
    CASE 
        WHEN cm.company_count IS NULL THEN 'No Companies'
        WHEN cm.production_companies > 0 THEN 'Produced by Companies'
        ELSE 'Independent'
    END AS movie_status,
    CASE 
        WHEN rm.production_age = 'Pre-1900' THEN 'Historic'
        ELSE 'Modern'
    END AS era
FROM 
    RankedMovies rm
LEFT JOIN ActorRoles ar ON rm.title_id = ar.movie_id AND ar.role_rank <= 3
LEFT JOIN CompanyMovies cm ON rm.title_id = cm.movie_id
LEFT JOIN MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    (rm.production_year > 2000 OR mk.keywords IS NOT NULL)
    AND (LOWER(rm.safe_title) LIKE '%love%' OR (mk.keywords IS NOT NULL AND mk.keywords LIKE '%action%'))
ORDER BY 
    rm.production_year DESC, rm.title;
