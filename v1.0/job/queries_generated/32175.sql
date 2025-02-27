WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        1 AS level,
        NULL AS parent_id
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2020)

    UNION ALL

    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.level + 1,
        ah.person_id AS parent_id
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
    JOIN 
        aka_name a ON ci.person_id = a.person_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT ah.parent_id) AS co_stars_count,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ci.movie_id) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_status
FROM 
    ActorHierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
JOIN 
    aka_title at ON ci.movie_id = at.id
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
    AND at.production_year <= 2023
GROUP BY 
    a.actor_name
ORDER BY 
    co_stars_count DESC, movies_count DESC;

This SQL query utilizes a recursive common table expression (CTE) to build an actor hierarchy based on their collaborations in movies. It performs a series of joins to retrieve relevant information, count unique co-stars, total movies participated in, and aggregate keywords associated with their movies. Additionally, it categorizes actors based on the number of movies they've appeared in. The query filters results based on specific conditions related to the movie kind and production year, ensuring a focus on relatively recent productions.
