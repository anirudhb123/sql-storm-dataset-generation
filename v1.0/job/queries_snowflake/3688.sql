
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
ActorMovieCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(cm.companies, 'No Companies') AS production_companies,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    COALESCE(ac.actor_count, 0) AS actor_count,
    CASE 
        WHEN ac.actor_count >= 5 THEN 'Star-studded'
        WHEN ac.actor_count BETWEEN 3 AND 4 THEN 'Moderate Cast'
        ELSE 'Few Actors'
    END AS cast_description
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovieInfo cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    KeywordCount kc ON rt.title_id = kc.movie_id
LEFT JOIN 
    ActorMovieCount ac ON rt.title_id = ac.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
