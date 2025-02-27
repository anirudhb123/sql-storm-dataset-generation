WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.name) AS rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN name m ON m.id = mc.company_id
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_cnt
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_cnt, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5' 
        ELSE 'Other' 
    END AS ranking_category
FROM RankedMovies rm
LEFT JOIN ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE rm.production_year >= 2000
ORDER BY rm.production_year DESC, rm.rank;
