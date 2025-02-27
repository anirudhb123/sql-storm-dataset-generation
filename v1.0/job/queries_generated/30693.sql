WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ARRAY[a.name] AS actor_path,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id = (SELECT id FROM title WHERE title = 'Inception')  -- Example movie title

    UNION ALL

    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.actor_path || a.name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON ci.movie_id = (SELECT linked_movie_id FROM movie_link ml WHERE ml.movie_id = (SELECT id FROM title WHERE title = 'Inception') LIMIT 1)  -- Linking to another movie as example
    WHERE 
        ah.actor_path[1] IS DISTINCT FROM a.name  -- Prevent cycles
),

movie_cast AS (
    SELECT 
        t.title,
        t.production_year,
        array_agg(DISTINCT ak.name) AS cast_names,
        count(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),

company_roles AS (
    SELECT 
        mc.movie_id,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(mb.cast_names, '{}') AS cast_names,
    COALESCE(cr.company_count, 0) AS total_companies,
    ah.actor_count AS unique_cast_count,
    CASE
        WHEN ah.actor_count > 10 THEN 'Popular Movie'
        WHEN ah.actor_count BETWEEN 5 AND 10 THEN 'Moderately Popular'
        ELSE 'Not Popular'
    END AS popularity_label
FROM 
    title t
LEFT JOIN 
    movie_cast mb ON t.id = mb.movie_id
LEFT JOIN 
    company_roles cr ON t.id = cr.movie_id
LEFT JOIN 
    actor_hierarchy ah ON ah.person_id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id = t.id)
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, mb.actor_count DESC;
