WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieReviews AS (
    SELECT 
        m.movie_id,
        COUNT(m.id) AS review_count
    FROM 
        movie_info m
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'review')
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    COALESCE(mr.review_count, 0) AS total_reviews,
    ar.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieReviews mr ON rm.movie_id = mr.movie_id
WHERE 
    (ar.role_count IS NULL OR ar.role_count > 2)
ORDER BY 
    rm.production_year DESC, 
    total_reviews DESC, 
    ar.actor_name;
