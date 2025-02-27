WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_roles AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        rt.role AS role_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
),
high_cast_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.cast_count > (SELECT AVG(cast_count) FROM ranked_movies)
),
co_casts AS (
    SELECT 
        m.title,
        a1.name AS actor_one,
        a2.name AS actor_two
    FROM 
        cast_info ci1
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN 
        aka_name a1 ON ci1.person_id = a1.person_id
    JOIN 
        aka_name a2 ON ci2.person_id = a2.person_id
    JOIN 
        title m ON ci1.movie_id = m.id
)
SELECT 
    hcm.title,
    hcm.production_year,
    cr.actor_name,
    cr.role_name,
    COALESCE(co.cast_pairing, 'No co-actor information') AS cast_pairing,
    COALESCE(DENSE_RANK() OVER (ORDER BY hcm.cast_count), 0) AS cast_rank
FROM 
    high_cast_movies hcm
LEFT JOIN 
    cast_roles cr ON hcm.title = cr.movie_title AND hcm.production_year = cr.production_year
LEFT JOIN (
    SELECT 
        title,
        STRING_AGG(DISTINCT actor_one || ' & ' || actor_two, ', ') AS cast_pairing
    FROM 
        co_casts
    GROUP BY 
        title
) co ON hcm.title = co.title
WHERE 
    hcm.production_year IS NOT NULL
ORDER BY 
    hcm.production_year DESC, hcm.cast_count DESC;
