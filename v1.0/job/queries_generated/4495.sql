WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        AVG(CASE WHEN mr.rating IS NOT NULL THEN mr.rating ELSE 0 END) AS avg_rating,
        COUNT(mr.rating) AS rating_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id
    LEFT JOIN 
        movie_info_idx mi_idx ON mi.id = mi_idx.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        movie_link ml ON ml.movie_id = m.id
    LEFT JOIN 
        (SELECT movie_id, rating 
         FROM movie_rating 
         WHERE rating IS NOT NULL) mr ON mr.movie_id = m.id
    GROUP BY 
        m.id
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
),
enriched_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mr.avg_rating, 0) AS avg_rating,
        COALESCE(mr.rating_count, 0) AS rating_count,
        array_agg(DISTINCT CONCAT(ar.actor_name, ' as ', ar.role_name) ORDER BY ar.role_order) AS roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_ratings mr ON m.id = mr.movie_id
    LEFT JOIN 
        actor_roles ar ON ar.movie_id = m.id
    GROUP BY 
        m.id, m.title, mr.avg_rating, mr.rating_count
)
SELECT 
    e.movie_id,
    e.title,
    e.avg_rating,
    e.rating_count,
    e.roles
FROM 
    enriched_movies e
WHERE 
    e.avg_rating > 7.0
    AND e.rating_count > 5
ORDER BY 
    e.avg_rating DESC, 
    e.rating_count DESC
LIMIT 10;
