WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        COALESCE(kc.kind, 'Unknown Kind') AS movie_kind
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN cast_info c ON a.id = c.movie_id
    LEFT JOIN kind_type kc ON a.kind_id = kc.id
    GROUP BY a.id, a.title, a.production_year, a.kind_id, mk.keyword, kc.kind
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
FullMovieDetails AS (
    SELECT
        m.title,
        m.production_year,
        m.movie_keyword,
        m.movie_kind,
        ac.actor_count
    FROM RankedMovies m
    JOIN ActorCounts ac ON m.id = ac.movie_id
    WHERE m.rank = 1
)
SELECT 
    f.title,
    f.production_year,
    f.movie_keyword,
    f.movie_kind,
    CASE 
        WHEN f.actor_count >= 10 THEN 'Blockbuster'
        WHEN f.actor_count BETWEEN 5 AND 9 THEN 'Moderate Success'
        ELSE 'Indie Film'
    END AS revenue_potential,
    CASE 
        WHEN f.movie_kind IS NULL THEN 'Unknown' 
        ELSE f.movie_kind 
    END AS finalized_kind
FROM FullMovieDetails f
WHERE f.movie_keyword IS NOT NULL
ORDER BY f.production_year DESC, f.actor_count DESC
LIMIT 10;

-- Performance benchmark with unusual semantics
SELECT 
    title,
    COUNT(*) AS referenced_count,
    SUM(CASE WHEN EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = t.id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    ) THEN 1 ELSE 0 END) AS has_rating_info,
    STRING_AGG(DISTINCT COALESCE(mn.name, 'No Cast'), ', ') AS main_cast
FROM aka_title t
OUTER JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
INNER JOIN movie_info mi ON t.id = mi.movie_id
LEFT JOIN cast_info ci ON t.id = ci.movie_id
LEFT JOIN name mn ON ci.person_id = mn.id
WHERE t.production_year >= 2000
GROUP BY t.id, t.title
HAVING COUNT(DISTINCT ci.person_id) > 1
ORDER BY referenced_count DESC, t.title
FETCH FIRST 20 ROWS ONLY;
