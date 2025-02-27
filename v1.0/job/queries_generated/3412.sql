WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank_per_kind
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
),
ActorInfo AS (
    SELECT 
        an.id AS actor_id,
        an.name AS actor_name,
        ac.movie_count
    FROM aka_name an
    JOIN ActorMovieCount ac ON an.person_id = ac.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
)
SELECT 
    ai.actor_name,
    m.title,
    COALESCE(mw.keywords, 'No keywords') AS keywords,
    rt.production_year,
    CASE 
        WHEN rt.rank_per_kind = 1 THEN 'Latest'
        ELSE 'Not Latest'
    END AS title_rank
FROM ActorInfo ai
JOIN cast_info ci ON ai.actor_id = ci.person_id
JOIN RankedTitles rt ON ci.movie_id = rt.id
LEFT JOIN MoviesWithKeywords mw ON rt.id = mw.movie_id
WHERE rt.rank_per_kind <= 5
AND ai.movie_count > 2
ORDER BY rt.production_year DESC, ai.actor_name;
