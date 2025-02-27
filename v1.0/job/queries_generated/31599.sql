WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL  -- Start with root movies
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS mh ON e.episode_of_id = mh.movie_id
),
actor_roles AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        ci.note,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    WHERE 
        a.name IS NOT NULL
),
most_frequent_roles AS (
    SELECT 
        actor_id,
        COUNT(*) AS role_count
    FROM 
        actor_roles
    GROUP BY 
        actor_id
    HAVING 
        COUNT(*) > 1
),
actor_info AS (
    SELECT 
        ar.actor_id,
        ar.name,
        COALESCE(mfr.role_count, 0) AS multiple_roles,
        mh.title AS related_movie,
        mh.production_year
    FROM 
        actor_roles AS ar
    LEFT JOIN 
        most_frequent_roles AS mfr ON ar.actor_id = mfr.actor_id
    LEFT JOIN 
        movie_hierarchy AS mh ON ar.movie_id = mh.movie_id
    WHERE 
        ar.role_order <= 3  -- Limit to top 3 roles per actor
)
SELECT 
    a.actor_id,
    a.name,
    a.multiple_roles,
    a.related_movie,
    COUNT(DISTINCT m.id) AS total_movies_in_series
FROM 
    actor_info AS a
LEFT JOIN 
    aka_title AS m ON a.related_movie = m.title
GROUP BY 
    a.actor_id, a.name, a.multiple_roles, a.related_movie
HAVING 
    COUNT(DISTINCT m.id) > 1
ORDER BY 
    a.multiple_roles DESC, a.name;
