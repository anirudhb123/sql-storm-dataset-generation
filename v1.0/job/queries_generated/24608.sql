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
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS distinct_roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
), 
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(*) AS num_companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ac.movie_count, 0) AS actor_count,
    COALESCE(ac.distinct_roles, 0) AS total_distinct_roles,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    COALESCE(cms.num_companies, 0) AS total_companies,
    COALESCE(cms.distinct_company_types, 0) AS distinct_company_types,
    (CASE 
        WHEN rt.production_year < 1990 THEN 'Classic'
        WHEN rt.production_year BETWEEN 1990 AND 2000 THEN 'Modern'
        ELSE 'Recent'
     END) AS era
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoleCounts ac ON rt.title_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id IN (
            SELECT DISTINCT person_id 
            FROM aka_name 
            WHERE name ILIKE '%a%' -- Looking for names with letter 'a'
        )
    )
LEFT JOIN 
    MovieKeywordCounts mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    CompanyMovieStats cms ON rt.title_id = cms.movie_id
WHERE 
    rt.production_year < EXTRACT(YEAR FROM CURRENT_DATE)  -- Only past movies
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
