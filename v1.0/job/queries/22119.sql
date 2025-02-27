WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
), 
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
), 
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    CASE 
        WHEN ak.name IS NOT NULL THEN ak.name
        ELSE 'Unknown Actor'
    END AS leading_actor,
    COALESCE(mk.keyword_count, 0) AS keyword_total,
    COALESCE(ac.actor_count, 0) AS actor_total,
    COALESCE(ct.companies, 'No Companies') AS production_companies,
    rt.rank_per_year
FROM RankedTitles rt
LEFT JOIN aka_name ak ON ak.person_id = (
    SELECT ci.person_id FROM cast_info ci
    WHERE ci.movie_id = rt.title_id
    ORDER BY ci.nr_order LIMIT 1
)
LEFT JOIN MovieKeywordCounts mk ON mk.movie_id = rt.title_id
LEFT JOIN ActorMovies ac ON ac.movie_id = rt.title_id
LEFT JOIN CompanyTitles ct ON ct.movie_id = rt.title_id
WHERE rt.rank_per_year <= 5
ORDER BY rt.production_year DESC, rt.rank_per_year
FETCH FIRST 10 ROWS ONLY;
