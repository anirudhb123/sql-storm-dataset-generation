WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        0 AS level
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1
    
    UNION ALL

    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id AND c.nr_order = ah.level + 1
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mi.info_details, 'No info') AS additional_info,
    ah.level AS actor_level
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = t.id
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = t.id
LEFT JOIN 
    ActorHierarchy ah ON ah.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (mk.keywords IS NOT NULL OR mi.info_details IS NOT NULL)
ORDER BY 
    t.production_year DESC, a.name;
