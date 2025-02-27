WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year 
    FROM title t 
    WHERE t.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count 
    FROM aka_name a 
    JOIN cast_info c ON a.person_id = c.person_id 
    GROUP BY a.person_id, a.name 
    HAVING COUNT(DISTINCT c.movie_id) > 5
),
CoActors AS (
    SELECT 
        ci.person_id AS actor_id, 
        COUNT(DISTINCT ci2.person_id) AS co_actor_count 
    FROM cast_info ci 
    JOIN cast_info ci2 ON ci.movie_id = ci2.movie_id AND ci.person_id <> ci2.person_id 
    GROUP BY ci.person_id
),
MoviesWithKeyword AS (
    SELECT 
        m.title AS movie_title, 
        k.keyword AS keyword 
    FROM aka_title m 
    JOIN movie_keyword mk ON m.movie_id = mk.movie_id 
    JOIN keyword k ON mk.keyword_id = k.id 
    WHERE k.keyword LIKE '%action%'
),
TitlesForBenchmark AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        fa.name AS actor_name, 
        CAST(ka.name AS VARCHAR) AS co_star_name, 
        COALESCE(ca.co_actor_count, 0) AS co_actor_count
    FROM RankedTitles rt
    JOIN FilteredActors fa ON fa.movie_count > 0 
    LEFT JOIN CoActors ca ON fa.person_id = ca.actor_id
    LEFT JOIN cast_info ci ON fa.person_id = ci.person_id 
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
    WHERE rt.rank_within_year <= 3
    ORDER BY rt.production_year DESC, rt.title
)
SELECT 
    title, 
    production_year, 
    actor_name, 
    STRING_AGG(co_star_name, ', ' ORDER BY co_star_name) AS co_stars,
    MAX(co_actor_count) AS max_co_actors
FROM TitlesForBenchmark
GROUP BY title, production_year, actor_name
HAVING COUNT(DISTINCT co_star_name) > 2 
   AND production_year >= 2000
ORDER BY production_year DESC, actor_name;
