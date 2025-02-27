WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL AND c.role_id = (SELECT id FROM role_type WHERE role = 'Actor')
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info c ON c.movie_id = (
            SELECT 
                movie_id 
            FROM 
                complete_cast 
            WHERE 
                subject_id = ah.person_id
        )
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id
)
SELECT 
    ah.actor_name,
    mi.title,
    mi.production_year,
    mi.company_count,
    mi.keyword_count,
    DENSE_RANK() OVER (PARTITION BY mi.production_year ORDER BY mi.keyword_count DESC) AS keyword_rank
FROM 
    ActorHierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    MovieInfo mi ON ci.movie_id = mi.movie_id
WHERE 
    mi.keyword_count > 0
ORDER BY 
    mi.production_year, keyword_rank
LIMIT 100;
