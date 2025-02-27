WITH recursive movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 5  -- Limit depth to avoid excessive recursion
),
actor_info AS (
    SELECT 
        p.id AS person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        keyword k ON ci.movie_id = (SELECT movie_id FROM movie_keyword WHERE keyword_id = k.id LIMIT 1)
    JOIN 
        person_info pi ON a.person_id = pi.person_id
    GROUP BY 
        p.id, a.name
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(SUM(mi.info_type_id IS NOT NULL)::INTEGER, 0) AS info_count,
        COALESCE(SUM(mk.keyword_id IS NOT NULL)::INTEGER, 0) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    mh.title,
    mh.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    md.info_count,
    md.keyword_count,
    dense_rank() OVER (PARTITION BY mh.movie_id ORDER BY ai.movie_count DESC) AS actor_rank
FROM 
    movie_hierarchy mh
JOIN 
    actor_info ai ON EXISTS (
        SELECT 1
        FROM cast_info ci
        WHERE ci.movie_id = mh.movie_id AND ci.person_id = ai.person_id
    )
JOIN 
    movie_details md ON mh.movie_id = md.movie_id
WHERE 
    md.info_count > 0
ORDER BY 
    mh.production_year DESC,
    actor_rank
LIMIT 50;

-- This query structures a recursive CTE to generate a list of movie links,
-- aggregates actor information based on their roles and movie appearances,
-- retrieves details about the number of informational types and keywords associated
-- with the movies, while also handling NULL logic, complex joins, and window functions
-- for ranking actors per movie.
