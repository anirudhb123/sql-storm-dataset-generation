WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.role_id IS NOT NULL
    UNION ALL
    SELECT 
        ci.person_id,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.person_id 
    WHERE 
        ci.role_id IS NOT NULL
),
MovieYears AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year BETWEEN 2000 AND 2020
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
AggregateInfo AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(t.production_year) AS latest_year,
        SUM(CASE WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director') THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        KeywordCount kc ON ci.movie_id = kc.movie_id
    WHERE 
        t.production_year IS NOT NULL AND 
        (ci.note IS NULL OR ci.note != 'cameo')
    GROUP BY 
        ci.movie_id
)
SELECT 
    m.id,
    m.title,
    m.production_year,
    ai.actor_count,
    ai.latest_year,
    ai.director_count,
    CASE 
        WHEN ai.actor_count IS NULL THEN 'No Actors'
        ELSE CONCAT(ai.actor_count, ' Actors')
    END AS actor_summary,
    COALESCE(kc.keyword_count, 0) AS keyword_summary
FROM 
    title m
LEFT JOIN 
    AggregateInfo ai ON m.id = ai.movie_id
LEFT JOIN 
    KeywordCount kc ON m.id = kc.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2020 
ORDER BY 
    m.production_year DESC, 
    m.title ASC;