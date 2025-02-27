WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM aka_title at
    WHERE at.production_year >= 2000
), 
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        COUNT(*) OVER (PARTITION BY ci.person_id ORDER BY ci.nr_order ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
), 
NullCheck AS (
    SELECT 
        DISTINCT movie_id,
        COUNT(*) AS non_empty_keywords
    FROM movie_keyword
    WHERE keyword_id IS NOT NULL
    GROUP BY movie_id
), 
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
), 
MoviesWithMoreThanOneCompany AS (
    SELECT
        movie_id
    FROM 
        movie_companies
    GROUP BY 
        movie_id
    HAVING COUNT(*) > 1
), 
FinalResults AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COUNT(DISTINCT ar.person_id) AS actor_count,
        COALESCE(nc.non_empty_keywords, 0) AS keyword_count,
        STRING_AGG(DISTINCT ct.company_name, ', ') AS companies,
        CASE 
            WHEN COUNT(DISTINCT ct.company_name) > 3 THEN 'Multiple Companies'
            ELSE 'Few Companies'
        END AS company_diversity
    FROM 
        RankedTitles rt
    LEFT JOIN ActorRoles ar ON rt.title_id = ar.movie_id
    LEFT JOIN NullCheck nc ON rt.title_id = nc.movie_id
    LEFT JOIN CompanyTitles ct ON rt.title_id = ct.movie_id
    WHERE 
        rt.title_rank <= 5
        AND rt.production_year IS NOT NULL
        AND (ar.role IS NOT NULL OR ar.role_count > 1)
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
    HAVING 
        COUNT(DISTINCT ar.person_id) > 1 
        AND rt.production_year IN (SELECT DISTINCT production_year FROM RankedTitles)
    ORDER BY 
        rt.production_year DESC, actor_count DESC
)
SELECT 
    *,
    CASE 
        WHEN keyword_count = 0 THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM 
    FinalResults
WHERE 
    company_diversity = 'Multiple Companies'
    OR (actor_count > 5 AND keyword_count > 2)
    OR (production_year IS NULL AND title IS NULL)
ORDER BY 
    production_year DESC;
