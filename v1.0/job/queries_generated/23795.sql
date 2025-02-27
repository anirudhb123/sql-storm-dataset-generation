WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        th.level + 1
    FROM 
        title_hierarchy th
    JOIN 
        title t ON th.title_id = t.episode_of_id
)
, ranked_aka_names AS (
    SELECT 
        ak.person_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS rn
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
)
, cast_summary AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        MAX(t.production_year) AS last_movie_year
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        c.person_id
)
SELECT 
    ak.name AS actor_name,
    ts.title AS movie_title,
    ts.production_year,
    cs.total_movies,
    CASE 
        WHEN cs.last_movie_year IS NULL THEN 'No Movies'
        ELSE CAST(cs.last_movie_year AS TEXT)
    END AS last_movie_year,
    th.level AS hierarchy_level
FROM 
    ranked_aka_names ak
LEFT JOIN 
    cast_summary cs ON ak.person_id = cs.person_id
LEFT JOIN 
    title_hierarchy th ON th.title_id IN (
        SELECT 
            t.id
        FROM 
            title t
        JOIN 
            cast_info c ON t.id = c.movie_id
        WHERE 
            c.person_id = ak.person_id
    )
JOIN 
    title ts ON ts.id = th.title_id
WHERE 
    ak.rn = 1 
AND 
    (cs.total_movies > 5 OR cs.last_movie_year IS NOT NULL)
ORDER BY 
    th.level DESC, 
    ak.name, 
    ts.production_year DESC
LIMIT 100;
