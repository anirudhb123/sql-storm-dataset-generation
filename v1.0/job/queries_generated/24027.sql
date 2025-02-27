WITH RecursiveActorTitle AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
PopularTitles AS (
    SELECT 
        title_id,
        COUNT(*) AS actor_count
    FROM 
        RecursiveActorTitle
    GROUP BY 
        title_id
    HAVING 
        COUNT(*) > 1
),
TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        kc.keyword AS top_keyword,
        mt.name AS top_company,
        mt.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY kc.id) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type mt ON mc.company_type_id = mt.id
),
FinalOutput AS (
    SELECT 
        ra.actor_id,
        ra.title,
        ra.production_year,
        td.top_keyword,
        CASE 
            WHEN td.top_company IS NOT NULL THEN td.top_company 
            ELSE 'Unknown Company' 
        END AS company,
        COALESCE(td.company_type, 'N/A') AS company_type,
        ra.rn
    FROM 
        RecursiveActorTitle ra
    JOIN 
        TitleDetails td ON ra.title_id = td.title_id
    WHERE 
        ra.rn = 1
)

SELECT 
    f.actor_id,
    f.title,
    f.production_year,
    f.top_keyword,
    f.company,
    f.company_type,
    CASE 
        WHEN f.company IS NULL OR f.top_keyword IS NULL THEN 'Missing Information'
        ELSE 'All Information Present'
    END AS info_status
FROM 
    FinalOutput f
JOIN 
    PopularTitles pt ON f.title_id = pt.title_id
ORDER BY 
    f.production_year DESC, 
    f.actor_id;
