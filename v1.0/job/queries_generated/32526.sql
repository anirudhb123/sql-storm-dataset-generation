WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        c.title,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title c ON ci.movie_id = c.movie_id
    WHERE 
        ci.nr_order = 1  -- Top-billed actors

    UNION ALL

    SELECT 
        ci.person_id,
        c.title,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_title c ON ci.movie_id = c.movie_id
    JOIN 
        ActorHierarchy ah ON ci.person_id = ah.person_id  -- Connect to next level
    WHERE 
        ci.nr_order > 1
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorFilmography AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        string_agg(DISTINCT at.title, ', ') AS movies,
        COUNT(DISTINCT at.id) AS movie_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT at.id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    LEFT JOIN 
        MovieKeywords mk ON at.movie_id = mk.movie_id
    GROUP BY 
        a.id, a.name, mk.keywords
    HAVING 
        COUNT(DISTINCT at.id) > 1  -- Only actors in more than one movie
)
SELECT 
    ah.actor_id,
    ah.actor_name,
    ah.movies,
    ah.movie_count,
    ah.keywords,
    CASE 
        WHEN ah.rank <= 10 THEN 'Top Actor'
        ELSE 'Regular Actor'
    END AS actor_type,
    ci.note AS character_note
FROM 
    ActorFilmography ah
LEFT JOIN 
    cast_info ci ON ah.actor_id = ci.person_id
ORDER BY 
    ah.movie_count DESC,
    ah.actor_name;
