WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        c.movie_id,
        t.title,
        c.status_id,
        1 AS level
    FROM 
        complete_cast c
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        c.status_id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id,
        t.title,
        c.status_id,
        mh.level + 1 
    FROM 
        movie_link mc
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        title t ON mc.linked_movie_id = t.id
    JOIN 
        complete_cast c ON mc.linked_movie_id = c.movie_id
    WHERE 
        c.status_id IS NOT NULL
)
, ActorInfo AS (
    SELECT
        ak.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS movies,
        COUNT(DISTINCT t.id) AS movie_count,
        COALESCE(STRING_AGG(DISTINCT tk.keyword, ', '), 'No keywords') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    GROUP BY 
        ak.person_id
)
SELECT 
    ai.actor_name,
    ai.movie_count,
    CASE 
        WHEN ai.movie_count = 0 THEN 'No Movies'
        WHEN ai.movie_count < 5 THEN 'Few Movies'
        ELSE 'Many Movies' 
    END AS movie_category,
    mh.movie_id,
    mh.title,
    mh.level AS relational_level,
    mh.status_id
FROM 
    ActorInfo ai
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id IN (
        SELECT movie_id 
        FROM complete_cast cc 
        WHERE cc.person_id IN (
            SELECT person_id 
            FROM aka_name 
            WHERE name ILIKE '%Smith%'
        )
    )
WHERE 
    ai.movie_count > 0
ORDER BY 
    ai.movie_count DESC, 
    mh.level ASC NULLS LAST
LIMIT 100;
