WITH MovieInfo AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        a.name AS actor_name,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS cast_count
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE m.production_year BETWEEN 2000 AND 2023
      AND a.name IS NOT NULL
      AND k.keyword IS NOT NULL
    GROUP BY m.title, m.production_year, a.name, k.keyword, ct.kind
),
ActorKeywordStats AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(cast_count) AS max_cast_count
    FROM MovieInfo
    GROUP BY actor_name
)
SELECT 
    actor_name,
    movie_count,
    keywords,
    max_cast_count
FROM ActorKeywordStats
ORDER BY movie_count DESC, max_cast_count DESC;
