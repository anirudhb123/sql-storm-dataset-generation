WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
actor_roles AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        COUNT(c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id, ak.name, rt.role
),
movie_rating AS (
    SELECT 
        m.movie_id,
        AVG(CASE WHEN m.note IS NOT NULL THEN 1 ELSE 0 END) AS rating
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    ar.actor_name,
    ar.role_name,
    mr.rating
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_roles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    movie_rating mr ON rm.movie_id = mr.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC, ar.role_count DESC;
