WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ca.person_id, a.name
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.name IS NOT NULL
),
KeywordStatistics AS (
    SELECT 
        mk.movie_id, 
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
RecentTitles AS (
    SELECT DISTINCT 
        t.title,
        t.production_year
    FROM 
        title t
    WHERE 
        t.production_year > 2010
),
ComplexJoin AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(ki.keyword_count, 0) AS keyword_count,
        COALESCE(adr.actor_count, 0) AS actor_count,
        ci.company_type
    FROM 
        RankedMovies rt
    LEFT JOIN KeywordStatistics ki ON rt.title_id = ki.movie_id
    LEFT JOIN ActorDetails adr ON rt.title_id = adr.movie_id
    LEFT JOIN CompanyInfo ci ON rt.title_id = ci.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    keyword_count,
    actor_count,
    company_type,
    CASE 
        WHEN actor_count > 0 AND keyword_count > 0 THEN 'High Engagement'
        WHEN actor_count = 0 AND keyword_count = 0 THEN 'No Engagement'
        ELSE 'Moderate Engagement' 
    END AS engagement_level,
    CASE 
        WHEN production_year IS NULL THEN 'Year Unknown'
        ELSE 'Year Known'
    END AS year_status
FROM 
    ComplexJoin
ORDER BY 
    production_year DESC, title ASC
LIMIT 100;
