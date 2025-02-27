WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.phonetic_code,
        ct.kind AS company_type,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        kind_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name a ON a.id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.phonetic_code,
        mh.company_type,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        title t ON t.id = ml.linked_movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.id = ci.person_id
    WHERE 
        mh.level < 5  -- limit depth to prevent infinite recursion
),

actor_movie_counts AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_hierarchy
    GROUP BY 
        actor_name
),

ranked_actors AS (
    SELECT 
        actor_name,
        movie_count,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        actor_movie_counts
)

SELECT 
    r.actor_name,
    r.movie_count,
    CASE
        WHEN r.actor_rank <= 10 THEN 'Top Actor'
        WHEN r.movie_count > 5 THEN 'Frequent Contributor'
        ELSE 'Occasional Actor'
    END AS actor_category,
    STRING_AGG(DISTINCT CONCAT(h.title, ' (', h.production_year, ')'), '; ') AS movie_titles,
    MAX(h.production_year) AS last_movie_year
FROM 
    ranked_actors r
JOIN 
    movie_hierarchy h ON h.actor_name = r.actor_name
WHERE 
    h.production_year > (CURRENT_YEAR - 20)  -- focus on recent movies
GROUP BY 
    r.actor_name, r.movie_count, r.actor_rank
HAVING 
    COUNT(DISTINCT h.movie_id) > 1
ORDER BY 
    r.actor_rank;
