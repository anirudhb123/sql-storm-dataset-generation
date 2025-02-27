WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        actor_hierarchy ah ON ah.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
highest_role AS (
    SELECT 
        c.movie_id,
        r.role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),
final_output AS (
    SELECT 
        ah.actor_name,
        ah.movie_title,
        mk.all_keywords,
        COALESCE(hr.role, 'Unknown') AS highest_role,
        ah.level
    FROM 
        actor_hierarchy ah
    LEFT JOIN 
        movie_keywords mk ON mk.movie_id = (SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ah.person_id)
    LEFT JOIN 
        highest_role hr ON hr.movie_id = (SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ah.person_id)
    WHERE 
        ah.level < 3
)
SELECT 
    actor_name,
    movie_title,
    all_keywords,
    highest_role,
    ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY movie_title) AS rn
FROM 
    final_output
WHERE 
    all_keywords IS NOT NULL
ORDER BY 
    actor_name, level, movie_title;
