WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        ci.nr_order = 1  -- Let's say we start with the leads
    UNION ALL
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ah.movie_title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
)
SELECT 
    a.id AS actor_id,
    ak.name AS actor_name,
    a.movie_title,
    a.production_year,
    COUNT(DISTINCT ca.id) OVER (PARTITION BY a.actor_id) AS co_starring_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN a.production_year IS NULL THEN 'No Year'
        ELSE a.production_year::TEXT
    END AS production_year_display,
    COALESCE(n.gender, 'Unknown') AS actor_gender
FROM 
    actor_hierarchy a
JOIN 
    aka_name ak ON ak.person_id = a.actor_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT movie_id FROM aka_title WHERE title = a.movie_title LIMIT 1)
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    name n ON n.imdb_id = ak.id
WHERE 
    a.level <= 3  -- Including actors from supporting roles as well
GROUP BY 
    a.actor_id, ak.name, a.movie_title, a.production_year, n.gender
ORDER BY 
    co_starring_count DESC, a.production_year DESC NULLS LAST;
