WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank_within_actor
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        actor_id,
        COUNT(movie_title) AS movie_count,
        MAX(production_year) AS last_movie_year
    FROM RankedMovies
    WHERE rank_within_actor <= 3
    GROUP BY actor_id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
QualifiedMovies AS (
    SELECT 
        rm.actor_id,
        rm.movie_title,
        rm.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        info.note AS movie_note
    FROM RankedMovies rm
    LEFT JOIN MovieKeywordCounts mkc ON rm.movie_title = mkc.movie_id
    LEFT JOIN movie_info mi ON rm.movie_title = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE rm.rank_within_actor <= 2 AND
          (it.info LIKE '%Oscar%' OR rm.production_year >= 2000)
)
SELECT 
    am.actor_id,
    a.name AS actor_name,
    COUNT(qm.movie_title) AS qualified_movie_count,
    SUM(qm.keyword_count) AS total_keywords,
    MAX(qm.production_year) AS last_qualified_movie_year
FROM ActorMovieCounts am
JOIN aka_name a ON am.actor_id = a.person_id
LEFT JOIN QualifiedMovies qm ON am.actor_id = qm.actor_id
GROUP BY am.actor_id, a.name
HAVING COUNT(qm.movie_title) >= 2
ORDER BY total_keywords DESC
LIMIT 10;

-- NOTE: This query benchmarks the performance of actor movie counts filtered by a mixture of qualification criteria
-- including year of production and associated keywords. It also integrates ranked results through CTEs,
-- uses window functions for ranking within partitions, and includes outer joins to retain relevant 
-- records while accommodating NULLs for missing associations.
