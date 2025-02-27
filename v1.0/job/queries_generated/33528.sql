WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        0 AS level,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        ak.name IS NOT NULL

    UNION ALL

    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ah.level + 1,
        t.title AS movie_title,
        t.production_year
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ci ON ah.actor_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        ah.level < 3 AND
        ak.name IS NOT NULL
),

MovieActors AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        COUNT(DISTINCT a.movie_title) AS movie_count,
        ARRAY_AGG(DISTINCT a.movie_title) AS movie_list
    FROM 
        ActorHierarchy a
    GROUP BY 
        a.actor_id, a.actor_name
),

KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

MoviesWithKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        KeywordCount kc ON mt.movie_id = kc.movie_id
)

SELECT 
    ma.actor_name,
    ma.movie_count,
    ma.movie_list,
    mwk.movie_title,
    mwk.keyword_count,
    CASE 
        WHEN mwk.keyword_count > 5 THEN 'High'
        WHEN mwk.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_density
FROM 
    MovieActors ma
JOIN 
    MoviesWithKeywords mwk ON ma.movie_list @> ARRAY[mwk.movie_title]
WHERE 
    ma.movie_count > 2
ORDER BY 
    ma.movie_count DESC, 
    mwk.keyword_count DESC;
