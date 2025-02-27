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
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), 
TitleKeywordSummary AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ac.actor_count,
    cm.company_count,
    COALESCE(tks.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN rt.title_rank = 1 THEN 'First Title of Production Year'
        WHEN rt.title_rank IS NULL THEN 'Missing Title'
        ELSE 'Subsequent Title'
    END AS title_rank_status
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCounts ac ON rt.title_id = ac.movie_id
FULL OUTER JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    TitleKeywordSummary tks ON rt.title_id = tks.movie_id
WHERE 
    rt.title IS NOT NULL
AND 
    (rt.production_year BETWEEN 1990 AND 2000 OR rt.production_year IS NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.title_rank ASC
LIMIT 100;
