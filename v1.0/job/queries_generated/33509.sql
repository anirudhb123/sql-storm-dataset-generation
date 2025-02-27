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
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    WHERE 
        a.name IS NOT NULL AND ah.level < 3
),

MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        mi.info AS info,
        COALESCE(ci.subject_id, -1) AS subject_id
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywordCount mk ON m.id = mk.movie_id
    LEFT JOIN 
        complete_cast ci ON m.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1)
)

SELECT 
    ma.title,
    ma.keyword_count,
    ah.actor_name,
    ROW_NUMBER() OVER (PARTITION BY ma.movie_id ORDER BY ma.keyword_count DESC) AS rank,
    CASE 
        WHEN ma.keyword_count > 10 THEN 'High'
        WHEN ma.keyword_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_intensity
FROM 
    MovieInfo ma
LEFT JOIN 
    ActorHierarchy ah ON ma.subject_id = ah.person_id
ORDER BY 
    ma.keyword_count DESC, ma.title;
