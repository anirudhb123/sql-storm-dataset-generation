WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        k.keyword AS movie_keyword,
        comp.name AS company_name,
        c.role_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name comp ON mc.company_id = comp.id
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE t.production_year >= 2000 
      AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
      AND k.keyword IS NOT NULL
),

KeywordStats AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT movie_keyword) AS keyword_count,
        COUNT(DISTINCT company_name) AS company_count,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM MovieDetails
    GROUP BY movie_title
),

FinalBenchmark AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.keyword_count,
        ms.company_count,
        ms.actor_count,
        CASE 
            WHEN ms.actor_count > 5 THEN 'Popular'
            ELSE 'Less Popular'
        END AS popularity
    FROM KeywordStats ms
    WHERE ms.keyword_count > 0
)

SELECT 
    fb.movie_title,
    fb.production_year,
    fb.keyword_count,
    fb.company_count,
    fb.actor_count,
    fb.popularity
FROM FinalBenchmark fb
ORDER BY fb.popularity DESC, fb.actor_count DESC, fb.movie_title;
