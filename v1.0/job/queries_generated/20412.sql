WITH RecursiveActors AS (
    -- Recursive CTE to fetch actors and their roles details
    SELECT 
        c.person_id, 
        c.movie_id, 
        r.role, 
        1 AS level
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order = 1
    
    UNION ALL
    
    SELECT 
        c.person_id, 
        c.movie_id, 
        r.role,
        ra.level + 1
    FROM 
        cast_info c
    JOIN 
        RecursiveActors ra ON ra.movie_id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id 
    WHERE 
        ra.level < 5 -- Limit recursion depth
),

MovieDetails AS (
    -- CTE to gather movie details and keywords
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COALESCE(COUNT(DISTINCT ca.movie_id), 0) AS actor_count,
        CASE WHEN COUNT(DISTINCT ca.movie_id) = 0 THEN NULL ELSE AVG(ca.actor_count) END AS avg_roles,
        MAX(CASE WHEN ca.actor_count > 1 THEN ca.actor_count END) AS max_roles
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        (SELECT 
             movie_id, 
             COUNT(DISTINCT person_id) AS actor_count 
         FROM 
             cast_info 
         GROUP BY 
             movie_id) ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    -- CTE for filtering logic with obscure predicates
    SELECT 
        md.movie_id, 
        md.title,
        md.production_year,
        md.keywords,
        md.actor_count,
        md.avg_roles,
        md.max_roles
    FROM 
        MovieDetails md
    WHERE 
        md.production_year IS NOT NULL
        AND (md.keywords IS NOT NULL OR md.actor_count > 2)
        AND (md.max_roles IS NOT NULL OR md.avg_roles < 2.5)
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(f.keywords, 'No keywords') AS keywords,
    f.actor_count,
    f.avg_roles,
    f.max_roles,
    CASE 
        WHEN f.actor_count = 0 THEN 'No cast' 
        ELSE 'Has cast' 
    END AS cast_status,
    CONCAT('Title: ', f.title, ' | Year: ', f.production_year) AS detailed_title
FROM 
    FilteredMovies f
LEFT JOIN 
    title tl ON f.movie_id = tl.id
LEFT JOIN 
    complete_cast cc ON f.movie_id = cc.movie_id
WHERE 
    tl.title IS NOT NULL 
    AND cc.status_id IS NULL  -- Only include movies with NULL status
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC;
