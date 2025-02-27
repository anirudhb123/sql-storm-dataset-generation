WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorInfo AS (
    SELECT 
        ca.person_id,
        ak.name AS actor_name,
        STRING_AGG(DISTINCT ct.kind, ', ') AS roles
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    LEFT JOIN 
        role_type ct ON ca.role_id = ct.id
    GROUP BY 
        ca.person_id, ak.name
), 
CompanyMovies AS (
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
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.roles,
    cm.companies,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS era
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    ActorInfo ai ON cc.subject_id = ai.person_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title IS NOT NULL 
    AND (rm.production_year BETWEEN 1980 AND 2023)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ai.actor_name, cm.companies
ORDER BY 
    rm.production_year DESC, 
    rm.title;
