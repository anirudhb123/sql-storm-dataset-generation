WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role LIKE 'Actor%')
),
movie_info_detail AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(ami.actor_name, 'No Actors') AS actor_name,
    rm.production_year,
    rm.rank,
    ami.actor_count,
    mid.movie_info
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_movies ami ON rm.movie_id = ami.movie_id
LEFT JOIN 
    movie_info_detail mid ON rm.movie_id = mid.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.rank;
