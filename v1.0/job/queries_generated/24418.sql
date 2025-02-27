WITH RecursiveMovie AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
        AND m.production_year > 2000

    UNION ALL 

    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title m
    JOIN RecursiveMovie rm ON rm.movie_id = m.id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.keyword IS NOT NULL
),
Top10Movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(*) OVER (PARTITION BY rm.production_year ORDER BY rm.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY COUNT(*) DESC) AS rn
    FROM 
        RecursiveMovie rm
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CompleteCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actors
    FROM 
        Top10Movies m
    LEFT JOIN cast_info cc ON m.movie_id = cc.movie_id
    LEFT JOIN aka_name p ON cc.person_id = p.person_id
    GROUP BY 
        m.movie_id
    HAVING COUNT(DISTINCT cc.person_id) > 0
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(cc.actor_count, 0) AS actor_count,
    COALESCE(cc.actors, 'Unknown') AS actors,
    CASE 
        WHEN keyword_count IS NULL THEN 'No Keywords Available' 
        ELSE keyword_count::text 
    END AS keyword_count
FROM 
    Top10Movies tm
LEFT JOIN CompleteCast cc ON tm.movie_id = cc.movie_id
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.production_year DESC,
    actor_count DESC NULLS LAST;

