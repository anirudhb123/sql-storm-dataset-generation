WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year
    FROM title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title) AS title,
        mh.level + 1,
        m.production_year
    FROM title m
    JOIN movie_link ml ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5 -- limit to 5 levels of sequel
),

MovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(NULLIF(AK.name, ''), 'Unknown') AS actor_name,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM MovieHierarchy mh
    LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
    LEFT JOIN aka_name AK ON AK.person_id = ci.person_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = mh.movie_id
    LEFT JOIN keyword kc ON kc.id = mk.keyword_id
    GROUP BY mh.movie_id, mh.title, mh.level, AK.name
),

RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.level,
        md.actor_name,
        md.keyword_count,
        RANK() OVER (PARTITION BY md.level ORDER BY md.keyword_count DESC) AS keyword_rank
    FROM MovieData md
)

SELECT 
    rm.level,
    rm.title,
    rm.actor_name,
    rm.keyword_count,
    rm.keyword_rank,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies
FROM RankedMovies rm
LEFT JOIN complete_cast cc ON cc.movie_id = rm.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = rm.movie_id
LEFT JOIN company_name cn ON cn.id = mc.company_id
WHERE rm.actor_name IS NOT NULL OR rm.actor_name <> 'Unknown'
GROUP BY rm.level, rm.title, rm.actor_name, rm.keyword_count, rm.keyword_rank
HAVING COUNT(DISTINCT mc.company_id) > 0
ORDER BY rm.level, rm.keyword_rank
LIMIT 100;

