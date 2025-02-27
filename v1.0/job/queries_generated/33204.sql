WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
  
    UNION ALL

    SELECT 
        ci.person_id,
        ah.actor_name,
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (
            SELECT 
                movie_id 
            FROM 
                cast_info ci2 
            WHERE 
                ci2.person_id = ah.person_id
        )
    WHERE 
        ci.person_id <> ah.person_id
),

MovieKeywords AS (
    SELECT 
        mv.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mv.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title mv
    JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mv.production_year >= 2000
),

ActorStats AS (
    SELECT 
        a.actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        COALESCE(AVG(mv.production_year), 0) AS avg_production_year,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM 
        ActorHierarchy a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title mv ON ci.movie_id = mv.id
    LEFT JOIN 
        MovieKeywords mk ON mv.title = mk.title
    GROUP BY 
        a.actor_name
)

SELECT 
    as.actor_name,
    as.movies_count,
    as.avg_production_year,
    CASE 
        WHEN as.movies_count > 0 THEN 
            'Active' 
        ELSE 
            'Inactive' 
    END AS activity_status,
    string_agg(DISTINCT k.keyword, ', ') AS keyword_list
FROM 
    ActorStats as
LEFT JOIN 
    LATERAL unnest(as.keywords) AS k ON true
GROUP BY 
    as.actor_name, as.movies_count, as.avg_production_year
ORDER BY 
    as.movies_count DESC, as.avg_production_year DESC;
