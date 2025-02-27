WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.imdb_index) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
PersonWithTitles AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT rt.title_id) AS title_count,
        MAX(rt.production_year) AS recent_production_year
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        a.person_id, a.name
),
MovieCompanyStats AS (
    SELECT 
        c.movie_id,
        m.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT cm.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_companies cm ON mc.movie_id = cm.movie_id
    GROUP BY 
        c.movie_id, m.name, ct.kind
),
KeywordAggregation AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    p.name AS actor_name,
    p.title_count,
    p.recent_production_year,
    CASE 
        WHEN p.title_count = 0 THEN 'No Titles'
        WHEN p.recent_production_year IS NULL THEN 'No Recent Productions'
        ELSE 'Active'
    END AS activity_status,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_name, 'No Companies') AS company_name,
    COALESCE(mc.company_type, 'Unknown Type') AS company_type,
    mc.total_companies
FROM 
    PersonWithTitles p
LEFT JOIN 
    KeywordAggregation k ON p.person_id = k.movie_id
LEFT JOIN 
    MovieCompanyStats mc ON mc.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id = p.person_id
    )
WHERE 
    p.title_count > 0 OR activity_status = 'Active'
ORDER BY 
    p.recent_production_year DESC NULLS LAST, 
    p.title_count DESC;
