WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id AS actor_id, 
        ca.movie_id, 
        1 AS depth
    FROM 
        cast_info ca
    WHERE 
        ca.role_id IS NOT NULL

    UNION ALL

    SELECT 
        ca.person_id, 
        ca.movie_id,
        ah.depth + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.person_id <> ah.actor_id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating,
        MAX(CASE WHEN it.info = 'Description' THEN mi.info END) AS description
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    m.title AS movie_title,
    a.name AS lead_actor,
    ah.depth AS coactor_count,
    mk.keywords,
    mi.rating,
    mi.description,
    COALESCE(m.production_year, 'Unknown Year') AS production_year,
    CASE
        WHEN mi.rating IS NULL THEN 'Unrated'
        ELSE 'Rated'
    END AS rating_status
FROM 
    aka_title m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id AND a.name_pcode_cf IS NOT NULL
LEFT JOIN 
    ActorHierarchy ah ON ah.movie_id = m.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = m.id
LEFT JOIN 
    MovieInfo mi ON mi.movie_id = m.id
WHERE 
    m.production_year >= 2000 
    AND (a.name IS NOT NULL OR m.title IS NOT NULL)
GROUP BY 
    m.title, a.name, ah.depth, mk.keywords, mi.rating, mi.description, m.production_year
ORDER BY 
    coactor_count DESC, production_year DESC
LIMIT 50;
