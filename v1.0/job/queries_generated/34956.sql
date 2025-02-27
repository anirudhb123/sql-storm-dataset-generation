WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        0 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE title ILIKE '%Avengers%') 
    UNION ALL
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (SELECT linked_movie_id FROM movie_link WHERE movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id))
    WHERE 
        ah.level < 3
),
MovieStats AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN at.production_year IS NOT NULL THEN EXTRACT(YEAR FROM NOW()) - at.production_year ELSE NULL END) AS avg_age
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    ms.avg_age,
    ks.keywords,
    ah.actor_name
FROM 
    MovieStats ms
LEFT JOIN 
    KeywordStats ks ON ms.movie_id = ks.movie_id
LEFT JOIN 
    ActorHierarchy ah ON ah.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = ms.movie_id)
WHERE 
    ms.avg_age < 50 
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC, 
    ah.actor_name ASC
LIMIT 10;
