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
MovieCompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
ActorStatistics AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(ck.role_id) AS average_role_id 
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type ck ON ci.role_id = ck.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
TitleWithNullCheck AS (
    SELECT 
        t.*,
        CASE 
            WHEN m.movie_id IS NULL THEN 'No Company' 
            ELSE 'Has Company' 
        END AS company_status
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.movie_id = m.movie_id
),
KeywordSearch AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 3
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    mc.company_name,
    mc.company_type,
    as.actor_name,
    as.movie_count,
    as.average_role_id,
    twn.company_status,
    ks.keyword,
    ks.movie_count
FROM 
    RankedTitles tt
LEFT JOIN 
    MovieCompanyDetails mc ON tt.title_id = mc.movie_id
LEFT JOIN 
    ActorStatistics as ON mc.movie_id = as.movie_count
LEFT JOIN 
    TitleWithNullCheck twn ON tt.title_id = twn.id
LEFT JOIN 
    KeywordSearch ks ON tt.title_id = ks.movie_count
WHERE 
    (tt.production_year < 2000 OR tt.production_year IS NULL)
    AND (mc.company_type IS NOT NULL OR as.movie_count > 10)
ORDER BY 
    tt.production_year DESC, 
    tt.title;
